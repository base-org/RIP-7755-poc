use anchor_lang::prelude::*;
use anchor_lang::solana_program::keccak;
use anchor_lang::solana_program::program::invoke;
use anchor_lang::solana_program::instruction::Instruction;
use precheck::program::Precheck;
use precheck::cpi::accounts::PrecheckCall;
use rip7755_structs::{self, CrossChainRequest};

mod fulfillment_info;

use fulfillment_info::FulfillmentInfo;

// This is your program's public key and it will update
// automatically when you build the project.
declare_id!("2nfLnXeeWyAUBsCT8uskj8nvkk46FiwaaVvDx29zQcue");

#[program]
mod rip_7755_inbox {
    use super::*;

    // TODO: should be using genesis hash instead of chain id
    pub const CHAIN_ID: u64 = 103; // devnet

    // there's a max limit to tx size, if calls need to be broken up, we need to call fulfill multiple times
    pub fn fulfill(ctx: Context<Fulfill>, request: CrossChainRequest, filler: Pubkey, accounts: Vec<TransactionAccount>) -> Result<()> {
        if request.destination_chain_id != CHAIN_ID {
            return Err(ErrorCode::InvalidChainId.into());
        }

        if ctx.program_id.clone() != request.inbox_contract {
            return Err(ErrorCode::InvalidInboxContract.into());
        }

        // Run precheck if configured
        if request.precheck_contract != Pubkey::default() {
            require!(
                ctx.accounts.precheck_contract.key() == request.precheck_contract,
                ErrorCode::InvalidPrecheckContract
            );

            let cpi_ctx = CpiContext::new(
                ctx.accounts.precheck_contract.to_account_info(),
                PrecheckCall {
                    caller: ctx.accounts.caller.to_account_info(),
                }
            );
    
            // Expecting the precheck call to revert if condition(s) not met
            precheck::cpi::precheck_call(cpi_ctx, request.clone(), ctx.accounts.caller.key())?;
        }

        // Check if fulfillment info already exists
        if ctx.accounts.fulfillment_info.exists {
            return Err(ErrorCode::CallAlreadyFulfilled.into());
        }

        // Initialize fulfillment info
        let request_hash = hash_request(&request)?;
        ctx.accounts.fulfillment_info.init(request_hash, filler)?;

        if request.calls.len() != 1 {
            return Err(ErrorCode::OnlyOneDstAccSupported.into());
        }

        // The remaining_accounts array provides access to all accounts passed in the transaction that aren't explicitly defined in the #[derive(Accounts)] struct.
        let remaining_accounts = &ctx.remaining_accounts;
        let mut account_metas = Vec::with_capacity(accounts.len());
        for acc in accounts.iter() {
            account_metas.push(AccountMeta::from(acc));
        }

        // Send calls
        let mut value_sent = 0;
        for call in &request.calls {
            let ix = Instruction {
                program_id: call.to,
                accounts: account_metas.clone(),
                data: call.data.clone(),
            };

            // Make call
            invoke(&ix, &ctx.remaining_accounts)?;

            value_sent += call.value;
        }

        // q: in evm, we check that msg.value == value_sent ... is there an equivalent here?
        // require!(
        //     value_sent == ctx.accounts.caller.lamports(),
        //     ErrorCode::InvalidValue
        // );

        Ok(())
    }
}

#[derive(Accounts)]
#[instruction(request: CrossChainRequest, filler: Pubkey, accounts: Vec<TransactionAccount>)]
pub struct Fulfill<'info> {
    #[account(init, payer = caller, space = 8 + 1 + 32 + 8 + 32)]
    pub fulfillment_info: Account<'info, FulfillmentInfo>,
    #[account(mut)]
    pub caller: Signer<'info>,
    pub system_program: Program<'info, System>,
    pub precheck_contract: Program<'info, Precheck>,
}

#[error_code]
pub enum ErrorCode {
    #[msg("Invalid chain ID")]
    InvalidChainId,
    #[msg("Invalid inbox contract")]
    InvalidInboxContract,
    #[msg("Call already fulfilled")]
    CallAlreadyFulfilled,
    #[msg("Invalid value")]
    InvalidValue,
    #[msg("Invalid precheck contract")]
    InvalidPrecheckContract,
    #[msg("Only one destination account supported for now")]
    OnlyOneDstAccSupported,
    #[msg("Invalid destination account")]
    InvalidDstAcc,
}

pub fn hash_request(request: &CrossChainRequest) -> Result<[u8; 32]> {
    let request_bytes = request.try_to_vec()?;
    let hash_result = keccak::hash(&request_bytes);
    Ok(hash_result.to_bytes())
}

#[derive(AnchorSerialize, AnchorDeserialize, Clone)]
pub struct TransactionAccount {
    pub pubkey: Pubkey,
    pub is_signer: bool,
    pub is_writable: bool,
}

impl From<&TransactionAccount> for AccountMeta {
    fn from(account: &TransactionAccount) -> AccountMeta {
        match account.is_writable {
            false => AccountMeta::new_readonly(account.pubkey, account.is_signer),
            true => AccountMeta::new(account.pubkey, account.is_signer),
        }
    }
}