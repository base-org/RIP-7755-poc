// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title IPrecheckContract
///
/// @author Coinbase (https://github.com/base-org/7755-poc)
///
/// @notice A Precheck Contract interface compatible with RRC-7755. A cross-chain-call can optionally specify a Precheck
///         Contract used to verify some arbitrary fulfillment condition during the `fulfill` transaction. To specify a
///         Precheck contract, set its address in a global request attribute using the `_PRECHECK_ATTRIBUTE_SELECTOR`
///         prefix.
interface IPrecheckContract {
    /// @notice A precheck function declaration.
    ///
    /// @param sourceChain The chain identifier of the source chain.
    /// @param sender      The account address of the sender.
    /// @param payload     The encoded calls to be included in the request.
    /// @param attributes  The attributes array.
    /// @param caller      The address of the filler account that submitted the transaction to RRC7755Inbox.
    function precheckCall(
        bytes32 sourceChain,
        bytes32 sender,
        bytes calldata payload,
        bytes[] calldata attributes,
        address caller
    ) external view;
}
