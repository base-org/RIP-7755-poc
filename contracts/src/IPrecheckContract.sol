// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {CrossChainCall} from "./RIP7755Structs.sol";

/// @title IPrecheckContract
///
/// @author Coinbase (https://github.com/base-org/7755-poc)
///
/// @notice A standardized interface for a valid Precheck Contract compatible with RIP-7755.
///
/// A cross-chain-call can optionally specify a Precheck Contract used to verify some arbitrary fill condition during the `fulfill` transaction.
/// To specify a Precheck contract, set its address in `CrossChainCall.precheckContract`.
/// In order for the cross chain call to succeed with a precheck, the Precheck contract must inherit this interface and implement `precheckCall`.
interface IPrecheckContract {
    /// @notice A precheck function declaration.
    ///
    /// @param crossChainCall A cross chain call request formatted following the RIP-7755 spec. See {RIP7755Structs-CrossChainCall}.
    /// @param caller The address of the filler account that submitted the transaction to RIP7755Verifier.
    function precheckCall(CrossChainCall calldata crossChainCall, address caller) external;
}
