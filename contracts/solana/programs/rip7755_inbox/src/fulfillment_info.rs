use anchor_lang::prelude::*;

#[account]
pub struct FulfillmentInfo {
    pub exists: bool, // 1
    pub key: [u8; 32], // 32
    pub timestamp: u64, // 8
    pub filler: Pubkey, // 32
}

impl FulfillmentInfo {
    pub fn init(&mut self, key: [u8; 32], filler: Pubkey) -> Result<()> {
        let clock = Clock::get()?;
        let current_timestamp = clock.unix_timestamp;

        self.exists = true;
        self.timestamp = u64::try_from(current_timestamp)?;
        self.filler = filler;
        self.key = key;

        Ok(())
    }
}
