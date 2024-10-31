use anchor_lang::prelude::*;
use anchor_lang::solana_program::keccak;
use precheck::program::Precheck;
use precheck::cpi::accounts::PrecheckCall;
use rip7755_structs::{self, CrossChainRequest};
use call_target::program::CallTarget;
use call_target::cpi::accounts::MakeCall;

mod fulfillment_info;

use fulfillment_info::FulfillmentInfo;

// This is your program's public key and it will update
// automatically when you build the project.
declare_id!("2nfLnXeeWyAUBsCT8uskj8nvkk46FiwaaVvDx29zQcue");

#[program]
mod rip7755_inbox {
    use super::*;

    // TODO: should be using genesis hash instead of chain id
    pub const CHAIN_ID: u64 = 103; // devnet

    // there's a max limit to tx size, if calls need to be broken up, we need to call fulfill multiple times
    pub fn fulfill(ctx: Context<Fulfill>, request: CrossChainRequest) -> Result<()> {
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
    
            // TODO: Do we need to handle the result if it fails?
            precheck::cpi::precheck_call(cpi_ctx, request.clone(), ctx.accounts.caller.key())?;
            // if res.is_err() {
            //     return Err(ErrorCode::PrecheckFailed.into());
            // }
        }

        // Check if fulfillment info already exists
        if ctx.accounts.fulfillment_info.exists {
            return Err(ErrorCode::CallAlreadyFulfilled.into());
        }

        // Initialize fulfillment info
        let request_hash = hash_request(&request)?;
        ctx.accounts.fulfillment_info.init(request_hash.to_vec(), ctx.accounts.filler.key())?;

        if request.calls.len() != 1 {
            return Err(ErrorCode::OnlyOneDstAccSupported.into());
        }
        
        // Send calls
        let mut value_sent = 0;
        for call in &request.calls {
            // validate dst acc
            require!(ctx.accounts.call_target.key() == call.to, ErrorCode::InvalidDstAcc);

            let cpi_ctx = CpiContext::new(
                ctx.accounts.call_target.to_account_info(),
                MakeCall {
                    caller: ctx.accounts.caller.to_account_info(),
                }
            );

            // Make call
            // TODO: Handle result?
            call_target::cpi::make_call(cpi_ctx, call.data.clone())?;
            value_sent += call.value;
        }

        // q: in evm, we check that msg.value == value_sent ... is there an equivalent here?
        require!(
            value_sent == ctx.accounts.caller.lamports(),
            ErrorCode::InvalidValue
        );

        Ok(())
    }
}

#[derive(Accounts)]
pub struct Fulfill<'info> {
    #[account(init, payer = filler, space = 8 + 1 + 32 + 8 + 32)]
    pub fulfillment_info: Account<'info, FulfillmentInfo>,
    #[account(mut)]
    pub filler: Signer<'info>,
    #[account(mut)]
    pub caller: Signer<'info>,
    pub system_program: Program<'info, System>,
    pub precheck_contract: Program<'info, Precheck>,
    pub call_target: Program<'info, CallTarget>, // starting with one call_target for now since the compiler doesn't like a dynamic array. ideally this is an array of accounts associated with the request calls array
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
    #[msg("Precheck failed")]
    PrecheckFailed,
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