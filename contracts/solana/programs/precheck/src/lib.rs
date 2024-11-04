use anchor_lang::prelude::*;
use rip7755_structs::{self, CrossChainRequest};

declare_id!("kXGFCQ2Bhj5z2zV9pPS7Ygz1PVt3EVYR7zTAGGcx7h9");

#[program]
pub mod precheck {
    use super::*;

    pub fn precheck_call(_ctx: Context<PrecheckCall>, request: CrossChainRequest, _caller: Pubkey) -> Result<()> {
        if request.reward_amount > 0 {
            return Err(ErrorCode::PrecheckFailed.into());
        }
        Ok(())
    }
}

#[derive(Accounts)]
pub struct PrecheckCall<'info> {
    #[account(mut)]
    pub caller: Signer<'info>,
}

#[error_code]
pub enum ErrorCode {
    #[msg("Precheck failed")]
    PrecheckFailed,
}
