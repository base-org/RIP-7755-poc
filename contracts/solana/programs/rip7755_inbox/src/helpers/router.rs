use crate::errors::ErrorCode;
use crate::types::*;
use anchor_lang::prelude::*;
use anchor_lang::solana_program::instruction::Instruction;
use anchor_lang::solana_program::program::invoke;

// Helper function for sending calls
pub fn send_calls(
    ctx: &Context<Fulfill>,
    request: &CrossChainRequest,
    accounts: &Vec<TransactionAccount>,
    offset: usize,
) -> Result<()> {
    for (index, call) in request.calls.iter().enumerate() {
        if call.data.len() > 0 {
            let mut metas = Vec::new();
            let mut remaining_accounts = vec![];

            // Filter accounts for the current call index
            // Assuming we cannot trust the order of accounts in the accounts array
            for acc in accounts
                .iter()
                .filter(|a| usize::from(a.call_index) == index)
            {
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

    **ctx
        .accounts
        .fulfillment_info
        .to_account_info()
        .try_borrow_mut_lamports()? -= amount;
    **to_account.try_borrow_mut_lamports()? += amount;

    Ok(())
}
