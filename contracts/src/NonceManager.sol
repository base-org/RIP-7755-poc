// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title NonceManager
///
/// @author Coinbase (https://github.com/base/RRC-7755-poc)
///
/// @notice This contract is used to manage the nonce for the RRC7755 protocol
abstract contract NonceManager {
    mapping(address => uint256) private _nonce;

    /// @notice Returns the nonce for the given account
    ///
    /// @param account The address of the account to get the nonce for
    ///
    /// @return nonce The nonce for the given account
    function getNonce(address account) public view returns (uint256) {
        return _nonce[account];
    }

    /// @notice Increments the nonce for the given account
    ///
    /// @param account The address of the account to increment the nonce for
    ///
    /// @return nonce The new nonce for the given account
    function _incrementNonce(address account) internal returns (uint256) {
        unchecked {
            // It would take ~3,671,743,063,080,802,746,815,416,825,491,118,336,290,905,145,409,708,398,004 years
            // with a sustained request rate of 1 trillion requests per second to overflow the nonce counter
            return ++_nonce[account];
        }
    }
}
