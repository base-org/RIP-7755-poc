use anchor_lang::prelude::*;
use rip7755_inbox::types::request::CrossChainRequest;

declare_id!("kXGFCQ2Bhj5z2zV9pPS7Ygz1PVt3EVYR7zTAGGcx7h9");

#[program]
pub mod precheck {
    use super::*;

    pub fn precheck_call(_ctx: Context<PrecheckCall>, data: PrecheckData) -> Result<()> {
        if data.request.reward_amount > 0 {
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

#[derive(AnchorSerialize, AnchorDeserialize)]
pub struct PrecheckData {
    request: CrossChainRequest,
    caller: Pubkey,
}

#[error_code]
pub enum ErrorCode {
    #[msg("Precheck failed")]
    PrecheckFailed,
}
