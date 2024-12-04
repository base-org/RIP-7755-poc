use crate::state::FulfillmentInfo;
use crate::CrossChainRequest;
use anchor_lang::prelude::*;

#[derive(Accounts, Clone)]
#[instruction(data: FulfillData)]
pub struct Fulfill<'info> {
    #[account(init, payer = caller, space = 8 + 8 + 32, seeds = [&data.request_hash], bump)]
    pub fulfillment_info: Account<'info, FulfillmentInfo>,
    #[account(mut)]
    pub caller: Signer<'info>,
    pub system_program: Program<'info, System>,
}

#[derive(AnchorSerialize, AnchorDeserialize, Clone)]
pub struct FulfillData {
    pub request: CrossChainRequest,
    pub filler: Pubkey,
    pub precheck_accounts: Vec<TransactionAccount>,
    pub accounts: Vec<TransactionAccount>,
    pub request_hash: Vec<u8>,
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
