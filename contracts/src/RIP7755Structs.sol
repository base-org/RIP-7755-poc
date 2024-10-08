// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

struct Call {
    // The address to call
    address to;
    // The calldata to call with
    bytes data;
    // The native asset value of the call
    uint256 value;
}

struct CrossChainCall {
    // Array of calls to make on the destination chain
    Call[] calls;
    // The contract on origin chain where this cross-chain call request originated
    address originationContract;
    // The chainId of the origin chain
    uint256 originChainId;
    // The chainId of the destination chain
    uint256 destinationChainId;
    // The nonce of this call, to differentiate from other calls with the same values
    uint256 nonce;
    // The L2 contract on destination chain that's storage will be used to verify whether or not this call was made
    address verifyingContract;
    // The L1 address of the contract that should have L2 block info stored
    address l2Oracle;
    // The storage key at which we expect to find the L2 block info on the l2Oracle
    bytes32 l2OracleStorageKey;
    // The address of the ERC20 reward asset to be paid to whoever proves they filled this call
    // Native asset specified as in ERC-7528 format
    address rewardAsset;
    // The reward amount to pay
    uint256 rewardAmount;
    // The minimum age of the L1 block used for the proof
    uint256 finalityDelaySeconds;
    // An optional pre-check contract address on the destination chain
    // Zero address represents no pre-check contract desired
    // Can be used for arbitrary validation of fill conditions
    address precheckContract;
    // Arbitrary encoded precheck data
    bytes precheckData;
}
