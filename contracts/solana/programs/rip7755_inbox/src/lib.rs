use anchor_lang::prelude::*;
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
        handle_precheck(&ctx, &request)?;

        // Initialize fulfillment info
        ctx.accounts.fulfillment_info.init(filler)?;

        send_calls(ctx, request, accounts)?;

        Ok(())
    }
}

#[derive(Accounts)]
#[instruction(request: CrossChainRequest, filler: Pubkey, accounts: Vec<TransactionAccount>)]
pub struct Fulfill<'info> {
    #[account(
        init, 
        payer = caller, 
        space = 8 + 8 + 32, 
        seeds = [
            request.requester.key().as_ref(),
            &request.nonce.to_be_bytes(),
        ],
        bump
    )]
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
    #[msg("Invalid precheck contract")]
    InvalidPrecheckContract,
    #[msg("Invalid precheck data")]
    InvalidPrecheckData,
    #[msg("Invalid account")]
    InvalidAccount,
}

#[derive(AnchorSerialize, AnchorDeserialize, Clone)]
pub struct TransactionAccount {
    pub pubkey: Pubkey,
    pub is_signer: bool,
    pub is_writable: bool,
    pub call_index: u8,
}

impl From<&TransactionAccount> for AccountMeta {
    fn from(account: &TransactionAccount) -> AccountMeta {
        match account.is_writable {
            false => AccountMeta::new_readonly(account.pubkey, account.is_signer),
            true => AccountMeta::new(account.pubkey, account.is_signer),
        }
    }
}

// Helper function for facilitating the precheck call if configured
// The precheck call is configured if extra_data is not empty and the first 32 bytes of the first element are not the default pubkey
fn handle_precheck(ctx: &Context<Fulfill>, request: &CrossChainRequest) -> Result<()> {
    if request.extra_data.len() > 0 { 
        let precheck_data = request.extra_data[0].clone();
    
        if precheck_data.len() < 32 {
            return Err(ErrorCode::InvalidPrecheckData.into());
        }

        // Extract the precheck contract from the first 32 bytes of extra_data and convert to pubkey
        let mut data_slice = [0; 32];
        data_slice.clone_from_slice(&precheck_data[0..32]);
        let precheck_contract = Pubkey::from(data_slice);
    
        // If the precheck contract is not the default pubkey, we need to call the precheck program
        if precheck_contract != Pubkey::default() {
            // Ensure the precheck program is the expected program
            require!(ctx.accounts.precheck_contract.key() == precheck_contract, ErrorCode::InvalidPrecheckContract);
    
            let cpi_ctx = CpiContext::new(
                ctx.accounts.precheck_contract.to_account_info(),
                PrecheckCall {
                    caller: ctx.accounts.caller.to_account_info(),
                }
            );
    
            // Expecting the precheck call to revert if condition(s) not met
            precheck::cpi::precheck_call(cpi_ctx, request.clone(), ctx.accounts.caller.key())?;
        }
    }
    Ok(())
}

// Helper function for sending calls
fn send_calls(ctx: Context<Fulfill>, request: CrossChainRequest, accounts: Vec<TransactionAccount>) -> Result<()> {
    for (index, call) in request.calls.iter().enumerate() {
        let mut metas = Vec::new();
        let mut remaining_accounts = vec![];

        // Filter accounts for the current call index
        // Assuming we cannot trust the order of accounts in the accounts array
        for acc in accounts.iter().filter(|a| usize::from(a.call_index) == index) {
            metas.push(AccountMeta::from(acc));
            // The remaining_accounts array provides access to all accounts passed in the transaction that aren't explicitly defined in the #[derive(Accounts)] struct.
            remaining_accounts.push(ctx.remaining_accounts[index].clone());

            if acc.pubkey != ctx.remaining_accounts[index].key() {
                return Err(ErrorCode::InvalidAccount.into());
            }
        }

        // Create the instruction for the current call
        let ix = Instruction {
            program_id: call.to,
            accounts: metas.clone(),
            data: call.data.clone(),
        };

        // Make call
        invoke(&ix, &remaining_accounts[..])?;
    }

    Ok(())
}