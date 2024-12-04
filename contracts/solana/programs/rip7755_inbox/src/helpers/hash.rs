use crate::types::*;
use anchor_lang::prelude::*;

pub fn hash_request(request: &CrossChainRequest) -> [u8; 32] {
    let serialized_data: Vec<u8> = request.try_to_vec().expect("Error serializing request");
    let hash = anchor_lang::solana_program::keccak::hash(&serialized_data);
    return hash.to_bytes();
}
