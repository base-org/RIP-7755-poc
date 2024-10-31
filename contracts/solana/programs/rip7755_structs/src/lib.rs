use anchor_lang::prelude::*;

declare_id!("TkF3SRA8NrukNfxxmkAdhWRxebivtE6uuaCNmrsGwTj");

#[program]
pub mod rip7755_structs {
}

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
    pub prover_contract: Pubkey,
    pub destination_chain_id: u64,
    pub inbox_contract: Pubkey,
    pub l2_oracle: Pubkey,
    pub l2_oracle_storage_key: [u8; 32],
    pub reward_asset: Pubkey,
    pub reward_amount: u64,
    pub finality_delay_seconds: u64,
    pub nonce: u64,
    pub expiry: u64,
    pub precheck_contract: Pubkey,
    pub precheck_data: Vec<u8>,
}
