use anchor_lang::error_code;

#[error_code]
pub enum ErrorCode {
    #[msg("Invalid chain ID")]
    InvalidChainId,
    #[msg("Invalid inbox contract")]
    InvalidInboxContract,
    #[msg("Invalid precheck data")]
    InvalidPrecheckData,
    #[msg("Invalid account")]
    InvalidAccount,
    #[msg("Invalid request hash")]
    InvalidRequestHash,
}
