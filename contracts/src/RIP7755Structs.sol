// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/// @notice Low-level call specs representing the desired transaction on destination chain
struct Call {
    /// @dev The address to call
    bytes32 to;
    /// @dev The calldata to call with
    bytes data;
    /// @dev The native asset value of the call
    uint256 value;
}

/// @notice A cross chain call request formatted following the RIP-7755 spec
struct CrossChainRequest {
    /// @dev The account submitting the cross chain request
    bytes32 requester;
    /// @dev Array of calls to make on the destination chain
    Call[] calls;
    /// @dev The chainId of the source chain
    uint256 sourceChainId;
    /// @dev The contract address the request was submitted to
    bytes32 origin;
    /// @dev The chainId of the destination chain
    uint256 destinationChainId;
    /// @dev The L2 contract on destination chain that's storage will be used to verify whether or not this call was made
    bytes32 inboxContract;
    /// @dev The L1 address of the contract that should have L2 block info stored
    bytes32 l2Oracle;
    /// @dev The storage key at which we expect to find the L2 block info on the l2Oracle
    bytes32 l2OracleStorageKey;
    /// @dev The address of the ERC20 reward asset to be paid to whoever proves they filled this call
    /// @dev Native asset specified as in ERC-7528 format
    bytes32 rewardAsset;
    /// @dev The reward amount to pay
    uint256 rewardAmount;
    /// @dev The minimum age of the L1 block used for the proof
    uint256 finalityDelaySeconds;
    /// @dev The nonce of this call, to differentiate from other calls with the same values
    uint256 nonce;
    /// @dev The timestamp at which this request will expire
    uint256 expiry;
    /// @dev Extra data to be included in the proof - this is extra data to be used for prechecks and special validation cases
    /// @dev The first element in the `extraData` array is reserved for the precheck
    /// @dev If no precheck is desired, set to an empty array. If no precheck is desired but other data is needed, set the first element in the array to the zero address
    bytes[] extraData;
}
