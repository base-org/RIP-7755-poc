use crate::errors::ErrorCode;
use crate::types::*;
use anchor_lang::prelude::*;
use anchor_lang::solana_program::instruction::Instruction;
use anchor_lang::solana_program::program::invoke;

// Helper function for facilitating the precheck call if configured
// The precheck call is configured if extra_data is not empty and the first 32 bytes of the first element are not the default pubkey
pub fn handle_precheck(
    ctx: &Context<Fulfill>,
    request: &CrossChainRequest,
    precheck_accounts: &Vec<TransactionAccount>,
) -> Result<()> {
    if request.extra_data.len() == 0 {
        return Ok(());
    }

    let precheck_contract = extract_precheck_contract(&request)?;

    if precheck_contract == Pubkey::default() {
        return Ok(());
    }

    // If the precheck contract is not the default pubkey, we need to call the precheck program
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

    make_call(
        &ctx,
        &request,
        &metas,
        &remaining_accounts,
        &precheck_contract,
    )?;

    Ok(())
}

fn extract_precheck_contract(request: &CrossChainRequest) -> Result<Pubkey> {
    let precheck_data = request.extra_data[0].clone();

    if precheck_data.len() < 32 {
        return Err(ErrorCode::InvalidPrecheckData.into());
    }
    // Extract the precheck contract from the first 32 bytes of extra_data and convert to pubkey
    let mut data_slice = [0; 32];
    data_slice.clone_from_slice(&precheck_data[0..32]);
    return Ok(Pubkey::from(data_slice));
}

fn make_call(
    ctx: &Context<Fulfill>,
    request: &CrossChainRequest,
    metas: &Vec<AccountMeta>,
    remaining_accounts: &Vec<AccountInfo>,
    precheck_contract: &Pubkey,
) -> Result<()> {
    let caller = ctx.accounts.caller.key();

    let precheck_data = PrecheckData {
        request: request.clone(),
        caller,
    };

    let mut serialized_data = Vec::new();
    precheck_data.serialize(&mut serialized_data).unwrap();

    // Discriminator for precheck_call function in precheck program
    let mut data: Vec<u8> = [72, 49, 94, 66, 197, 0, 175, 219].to_vec();
    data.extend_from_slice(&serialized_data);

    // Create the instruction for the current call
    let ix = Instruction {
        program_id: *precheck_contract,
        accounts: metas.clone(),
        data,
    };

    invoke(&ix, &remaining_accounts[..])?;

    Ok(())
}
