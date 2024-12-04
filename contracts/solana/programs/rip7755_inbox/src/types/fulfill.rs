use crate::state::FulfillmentInfo;
use crate::CrossChainRequest;
use anchor_lang::prelude::*;

#[derive(Accounts, Clone)]
#[instruction(
    request: CrossChainRequest,
    filler: Pubkey,
    precheck_accounts: Vec<TransactionAccount>,
    accounts: Vec<TransactionAccount>,
    request_hash: Vec<u8>
)]
pub struct Fulfill<'info> {
    #[account(init, payer = caller, space = 8 + 8 + 32, seeds = [&request_hash], bump)]
    pub fulfillment_info: Account<'info, FulfillmentInfo>,
    #[account(mut)]
    pub caller: Signer<'info>,
    pub system_program: Program<'info, System>,
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
    pub request: CrossChainRequest,
    pub caller: Pubkey,
}

impl From<&TransactionAccount> for AccountMeta {
    fn from(account: &TransactionAccount) -> AccountMeta {
        match account.is_writable {
            false => AccountMeta::new_readonly(account.pubkey, account.is_signer),
            true => AccountMeta::new(account.pubkey, account.is_signer),
        }
    }
}
