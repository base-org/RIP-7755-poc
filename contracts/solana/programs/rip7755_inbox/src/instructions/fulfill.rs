use crate::errors::ErrorCode;
use crate::helpers::*;
use crate::types::*;
use crate::CHAIN_ID;
use anchor_lang::prelude::*;

// there's a max limit to tx size, if calls need to be broken up, we need to call fulfill multiple times
pub fn fulfill(
    ctx: Context<Fulfill>,
    request: &CrossChainRequest,
    filler: &Pubkey,
    precheck_accounts: &Vec<TransactionAccount>,
    accounts: &Vec<TransactionAccount>,
    request_hash: &Vec<u8>,
) -> Result<()> {
    if request.destination_chain_id != CHAIN_ID {
        return Err(ErrorCode::InvalidChainId.into());
    }

    if ctx.program_id.clone() != request.inbox_contract {
        return Err(ErrorCode::InvalidInboxContract.into());
    }

    // confirm request_hash
    if *request_hash != hash_request(&request).to_vec() {
        return Err(ErrorCode::InvalidRequestHash.into());
    }

    // Run precheck if configured
    handle_precheck(&ctx, &request, &precheck_accounts)?;

    // Initialize fulfillment info
    ctx.accounts.fulfillment_info.init(*filler)?;

    // Transfer funds to the fulfillment info account if any calls are only lamport transfers
    deposit_transfer_funds(&ctx, &request)?;

    send_calls(&ctx, &request, &accounts, precheck_accounts.len())?;

    Ok(())
}
