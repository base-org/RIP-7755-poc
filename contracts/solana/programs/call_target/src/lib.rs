use anchor_lang::prelude::*;

declare_id!("4rPLqoMbtPAMdYeytQagQyt5ucVxRJpx7BjL2jW49UsQ");

#[program]
pub mod call_target {
    use super::*;

    pub fn make_call(ctx: Context<MakeCall>, _data: Vec<u8>) -> Result<()> {
        msg!("Greetings from: {:?}", ctx.program_id);
        Ok(())
    }
}

#[derive(Accounts)]
#[instruction(_data: Vec<u8>)]
pub struct MakeCall<'info> {
    #[account(mut)]
    pub caller: Signer<'info>,
}
