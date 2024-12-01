use anchor_lang::prelude::*;

#[derive(AnchorSerialize, AnchorDeserialize, Clone)]
pub struct Call {
    pub to: Pubkey,
    pub data: Vec<u8>,
    pub value: u64,
}

#[derive(AnchorSerialize, AnchorDeserialize, Clone)]
pub struct CrossChainRequest {
    pub requester: Pubkey,
    pub calls: Vec<Call>,
    pub destination_chain_id: u64,
    pub inbox_contract: Pubkey,
    pub l2_oracle: Pubkey,
    pub l2_oracle_storage_key: [u8; 32],
    pub reward_asset: Pubkey,
    pub reward_amount: u64,
    pub finality_delay_seconds: u64,
    pub nonce: u64,
    pub expiry: u64,
    pub extra_data: Vec<Vec<u8>>
}