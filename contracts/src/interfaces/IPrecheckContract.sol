// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {CrossChainRequest} from "../RIP7755Structs.sol";

/// @title IPrecheckContract
///
/// @author Coinbase (https://github.com/base-org/7755-poc)
///
/// @notice A standardized interface for a valid Precheck Contract compatible with RIP-7755.
///
/// A cross-chain-call can optionally specify a Precheck Contract used to verify some arbitrary fulfillment condition during the `fulfill` transaction.
/// To specify a Precheck contract, set its address in `CrossChainRequest.precheckContract`.
/// In order for the cross chain call to succeed with a precheck, the Precheck contract must inherit this interface and implement `precheckCall`.
interface IPrecheckContract {
    /// @notice A precheck function declaration.
    ///
    /// @param request A cross chain call request formatted following the RIP-7755 spec. See {RIP7755Structs-CrossChainRequest}.
    /// @param caller The address of the filler account that submitted the transaction to RIP7755Inbox.
    function precheckCall(CrossChainRequest calldata request, address caller) external;
}
