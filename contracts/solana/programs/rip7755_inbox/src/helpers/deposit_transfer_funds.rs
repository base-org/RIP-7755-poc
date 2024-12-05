use crate::types::*;
use anchor_lang::prelude::*;
use anchor_lang::solana_program::system_instruction;

// To aid in the lamport transfers to an unknown amount of accounts, we'll first transfer to the owned fulfillment info account
// and then transfer from there to the destination accounts
pub fn deposit_transfer_funds(ctx: &Context<Fulfill>, request: &CrossChainRequest) -> Result<()> {
    let mut amount = 0;

    for call in &request.calls {
        if call.data.len() == 0 {
            amount += call.value;
        }
    }

    if amount == 0 {
        return Ok(());
    }

    let transfer_instruction = system_instruction::transfer(
        &ctx.accounts.caller.key(),
        &ctx.accounts.fulfillment_info.key(),
        amount,
    );

    anchor_lang::solana_program::program::invoke_signed(
        &transfer_instruction,
        &[
            ctx.accounts.caller.to_account_info(),
            ctx.accounts.fulfillment_info.to_account_info(),
            ctx.accounts.system_program.to_account_info(),
        ],
        &[],
    )?;

    Ok(())
}
