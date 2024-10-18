// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {RIP7755Inbox} from "../RIP7755Inbox.sol";
import {CrossChainRequest} from "../RIP7755Structs.sol";

/// A Prover contract will validate proof data that a call actually happened on a destination chain. The exact details
/// for how that should be accomplished will vary slightly depending on the destination chain since not all rollups
/// post their data to L1 in the same format.
interface IProver {
    /// @notice Validates storage proofs and verifies fill
    ///
    /// @custom:reverts If storage proof invalid.
    /// @custom:reverts If fillInfo not found at inboxContractStorageKey on crossChainCall.verifyingContract
    /// @custom:reverts If fillInfo.timestamp is less than
    /// crossChainCall.finalityDelaySeconds from current destination chain block timestamp.
    ///
    /// @dev Implementation will vary by L2
    ///
    /// @param inboxContractStorageKey The storage location of the data to verify on the destination chain
    /// `RIP7755Inbox` contract
    /// @param fulfillmentInfo The fulfillment info that should be located at `inboxContractStorageKey` in storage
    /// on the destination chain `RIP7755Inbox` contract
    /// @param request The original cross chain request submitted to this contract
    /// @param proofData The proof to validate
    function validateProof(
        bytes memory inboxContractStorageKey,
        RIP7755Inbox.FulfillmentInfo calldata fulfillmentInfo,
        CrossChainRequest calldata request,
        bytes calldata proofData
    ) external view;
}
