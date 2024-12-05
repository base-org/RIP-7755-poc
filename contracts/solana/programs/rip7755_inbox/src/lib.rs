use anchor_lang::prelude::*;
use types::*;

pub mod errors;
pub mod helpers;
pub mod instructions;
pub mod state;
pub mod types;

// This is your program's public key and it will update
// automatically when you build the project.
declare_id!("2nfLnXeeWyAUBsCT8uskj8nvkk46FiwaaVvDx29zQcue");

#[program]
mod rip_7755_inbox {
    use super::*;

    // TODO: should be using genesis hash instead of chain id
    pub const CHAIN_ID: u64 = 103; // devnet

    // there's a max limit to tx size, if calls need to be broken up, we need to call fulfill multiple times
    pub fn fulfill(
        ctx: Context<Fulfill>,
        request: CrossChainRequest,
        filler: Pubkey,
        precheck_accounts: Vec<TransactionAccount>,
        accounts: Vec<TransactionAccount>,
        request_hash: Vec<u8>,
    ) -> Result<()> {
        instructions::fulfill::fulfill(
            ctx,
            &request,
            &filler,
            &precheck_accounts,
            &accounts,
            &request_hash,
        )?;

        Ok(())
    }
}
