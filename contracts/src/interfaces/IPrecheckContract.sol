// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC7786Base} from "../ERC7786Base.sol";

/// @title IPrecheckContract
///
/// @author Coinbase (https://github.com/base-org/7755-poc)
///
/// @notice A standardized interface for a valid Precheck Contract compatible with RIP-7755.
///
/// A cross-chain-call can optionally specify a Precheck Contract used to verify some arbitrary fulfillment condition during the `fulfill` transaction.
/// To specify a Precheck contract, set its address in a global request attribute using the `_PRECHECK_ATTRIBUTE_SELECTOR` prefix.
/// In order for the cross chain call to succeed with a precheck, the Precheck contract must inherit this interface and implement `precheckCall`.
interface IPrecheckContract {
    /// @notice A precheck function declaration.
    ///
    /// @param sourceChain The CAIP-2 chain identifier of the source chain.
    /// @param sender The CAIP-10 account address of the sender.
    /// @param messages The messages to be included in the request.
    /// @param globalAttributes The attributes array.
    /// @param caller The address of the filler account that submitted the transaction to RIP7755Inbox.
    function precheckCall(
        string calldata sourceChain,
        string calldata sender,
        ERC7786Base.Message[] calldata messages,
        bytes[] calldata globalAttributes,
        address caller
    ) external view;
}
