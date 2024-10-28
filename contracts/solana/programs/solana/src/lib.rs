use anchor_lang::prelude::*;

declare_id!("7zMxH5rPbZjh6AkehzNabfdQSRTpFYMbcgqtyaWKq5yL");

#[program]
pub mod solana {
    use super::*;

    pub fn initialize(ctx: Context<Initialize>) -> Result<()> {
        msg!("Greetings from: {:?}", ctx.program_id);
        Ok(())
    }
}

#[derive(Accounts)]
pub struct Initialize {}
