use anchor_lang::prelude::*;
use rip7755_structs::{self, CrossChainRequest};

declare_id!("kXGFCQ2Bhj5z2zV9pPS7Ygz1PVt3EVYR7zTAGGcx7h9");

#[program]
pub mod precheck {
    use super::*;

    pub fn precheck_call(ctx: Context<PrecheckCall>, _request: CrossChainRequest, _caller: Pubkey) -> Result<()> {
        msg!("Greetings from: {:?}", ctx.program_id);
        Ok(())
    }
}

#[derive(Accounts)]
pub struct PrecheckCall<'info> {
    #[account(mut)]
    pub caller: Signer<'info>,
}
