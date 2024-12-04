use anchor_lang::prelude::*;
use anchor_lang::solana_program::program::invoke;
use anchor_lang::solana_program::instruction::Instruction;
use anchor_lang::solana_program::system_instruction;

mod fulfillment_info;
mod structs;

use fulfillment_info::FulfillmentInfo;
pub use structs::CrossChainRequest;

// This is your program's public key and it will update
// automatically when you build the project.
declare_id!("2nfLnXeeWyAUBsCT8uskj8nvkk46FiwaaVvDx29zQcue");

#[program]
mod rip_7755_inbox {
    use super::*;

    // TODO: should be using genesis hash instead of chain id
    pub const CHAIN_ID: u64 = 103; // devnet

    // there's a max limit to tx size, if calls need to be broken up, we need to call fulfill multiple times
    pub fn fulfill(
        ctx: Context<Fulfill>, 
        request: CrossChainRequest, 
        filler: Pubkey, 
        precheck_accounts: Vec<TransactionAccount>, 
        accounts: Vec<TransactionAccount>,
        request_hash: Vec<u8>
    ) -> Result<()> {
        if request.destination_chain_id != CHAIN_ID {
            return Err(ErrorCode::InvalidChainId.into());
        }

        if ctx.program_id.clone() != request.inbox_contract {
            return Err(ErrorCode::InvalidInboxContract.into());
        }

        // confirm request_hash
        if request_hash != hash_request(&request) {
            return Err(ErrorCode::InvalidRequestHash.into());
        }

        // Run precheck if configured
        handle_precheck(&ctx, &request, &precheck_accounts)?;

        // Initialize fulfillment info
        ctx.accounts.fulfillment_info.init(filler)?;

        deposit_transfer_funds(&ctx, &request)?;

        send_calls(&ctx, &request, &accounts, precheck_accounts.len())?;

        Ok(())
    }
}

#[derive(Accounts, Clone)]
#[instruction(request: CrossChainRequest, filler: Pubkey, precheck_accounts: Vec<TransactionAccount>, accounts: Vec<TransactionAccount>, request_hash: Vec<u8>)]
pub struct Fulfill<'info> {
    #[account(
        init, 
        payer = caller, 
        space = 8 + 8 + 32, 
        seeds = [&request_hash],
        bump
    )]
    pub fulfillment_info: Account<'info, FulfillmentInfo>,
    #[account(mut)]
    pub caller: Signer<'info>,
    pub system_program: Program<'info, System>,
}

#[error_code]
pub enum ErrorCode {
    #[msg("Invalid chain ID")]
    InvalidChainId,
    #[msg("Invalid inbox contract")]
    InvalidInboxContract,
    #[msg("Invalid precheck data")]
    InvalidPrecheckData,
    #[msg("Invalid account")]
    InvalidAccount,
    #[msg("Invalid request hash")]
    InvalidRequestHash,
}

#[derive(AnchorSerialize, AnchorDeserialize, Clone)]
pub struct TransactionAccount {
    pub pubkey: Pubkey,
    pub is_signer: bool,
    pub is_writable: bool,
    pub call_index: u8,
}

#[derive(AnchorSerialize, AnchorDeserialize)]
pub struct PrecheckData {
    request: CrossChainRequest,
    caller: Pubkey,
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
fn handle_precheck(ctx: &Context<Fulfill>, request: &CrossChainRequest, precheck_accounts: &Vec<TransactionAccount>) -> Result<()> {
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
            let mut metas = Vec::new();
            let mut remaining_accounts = vec![];
            // Filter accounts for the current call index
            // Assuming we cannot trust the order of accounts in the accounts array
            for (index, acc) in precheck_accounts.iter().enumerate() {
                metas.push(AccountMeta::from(acc));
                // The remaining_accounts array provides access to all accounts passed in the transaction that aren't explicitly defined in the #[derive(Accounts)] struct.
                remaining_accounts.push(ctx.remaining_accounts[index].clone());

                if acc.pubkey != ctx.remaining_accounts[index].key() {
                    return Err(ErrorCode::InvalidAccount.into());
                }
            }

            let caller = ctx.accounts.caller.key();

            let precheck_data = PrecheckData {
                request: request.clone(),
                caller
            };

            let mut serialized_data = Vec::new();
            precheck_data.serialize(&mut serialized_data).unwrap();

            // Discriminator for precheck_call function in precheck program
            let mut data: Vec<u8> = [ 72, 49, 94, 66, 197, 0, 175, 219 ].to_vec();
            data.extend_from_slice(&serialized_data);

            // Create the instruction for the current call
            let ix = Instruction {
                program_id: precheck_contract,
                accounts: metas.clone(),
                data
            };

            invoke(&ix, &remaining_accounts[..])?;
        }
    }
    Ok(())
}

fn deposit_transfer_funds(ctx: &Context<Fulfill>, request: &CrossChainRequest) -> Result<()> {
    let mut amount = 0;

    for call in &request.calls {
        if call.data.len() == 0 {
            amount += call.value;
        }
    }

    if amount > 0 {
        let transfer_instruction = system_instruction::transfer(&ctx.accounts.caller.key(), &ctx.accounts.fulfillment_info.key(), amount);

        anchor_lang::solana_program::program::invoke_signed(
            &transfer_instruction,
            &[
                ctx.accounts.caller.to_account_info(),
                ctx.accounts.fulfillment_info.to_account_info(),
                ctx.accounts.system_program.to_account_info(),
            ],
            &[],
        )?;
    }

    Ok(())
}

// Helper function for sending calls
fn send_calls(ctx: &Context<Fulfill>, request: &CrossChainRequest, accounts: &Vec<TransactionAccount>, offset: usize) -> Result<()> {
    for (index, call) in request.calls.iter().enumerate() {
        if call.data.len() > 0 {
            let mut metas = Vec::new();
            let mut remaining_accounts = vec![];
    
            // Filter accounts for the current call index
            // Assuming we cannot trust the order of accounts in the accounts array
            for acc in accounts.iter().filter(|a| usize::from(a.call_index) == index) {
                metas.push(AccountMeta::from(acc));
                // The remaining_accounts array provides access to all accounts passed in the transaction that aren't explicitly defined in the #[derive(Accounts)] struct.
                remaining_accounts.push(ctx.remaining_accounts[index + offset].clone());
    
                if acc.pubkey != ctx.remaining_accounts[index + offset].key() {
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
        } else {
            send_lamports(ctx, call.to, call.value)?;
        }
    }

    Ok(())
}

fn send_lamports(ctx: &Context<Fulfill>, target: Pubkey, amount: u64) -> Result<()> {
    let to_account_option = ctx.remaining_accounts.iter().find(|a| a.key() == target);
    let to_account = to_account_option.expect("Missing target account").clone();

    **ctx.accounts.fulfillment_info.to_account_info().try_borrow_mut_lamports()? -= amount;
    **to_account.try_borrow_mut_lamports()? += amount;

    Ok(())
}

fn hash_request(request: &CrossChainRequest) -> [u8; 32] {
    let serialized_data: Vec<u8> = request.try_to_vec().expect("Error serializing request");
    let hash = anchor_lang::solana_program::keccak::hash(&serialized_data);
    return hash.to_bytes();
}