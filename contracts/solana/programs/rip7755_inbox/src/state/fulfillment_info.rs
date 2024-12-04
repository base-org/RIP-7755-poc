use anchor_lang::prelude::*;

#[account]
pub struct FulfillmentInfo {
    pub timestamp: u64, // 8
    pub filler: Pubkey, // 32
}

impl FulfillmentInfo {
    pub fn init(&mut self, filler: Pubkey) -> Result<()> {
        let clock = Clock::get()?;
        let current_timestamp = clock.unix_timestamp;

        self.timestamp = u64::try_from(current_timestamp)?;
        self.filler = filler;

        Ok(())
    }
}
