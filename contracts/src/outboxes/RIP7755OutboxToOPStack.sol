// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {OPStackProver} from "../libraries/provers/OPStackProver.sol";
import {RIP7755Inbox} from "../RIP7755Inbox.sol";
import {RIP7755Outbox} from "../RIP7755Outbox.sol";
import {CrossChainRequest} from "../RIP7755Structs.sol";

/// @title RIP7755OutboxToOPStack
///
/// @author Coinbase (https://github.com/base-org/RIP-7755-poc)
///
/// @notice This contract implements storage proof validation to ensure that requested calls actually happened on an OP Stack chain
contract RIP7755OutboxToOPStack is RIP7755Outbox {
    using OPStackProver for bytes;

    /// @notice This error is thrown when fulfillmentInfo.timestamp is less than request.finalityDelaySeconds from
    /// current destination chain block timestamp.
    error FinalityDelaySecondsInProgress();

    /// @notice Validates storage proofs and verifies fulfillment
    ///
    /// @custom:reverts If storage proof invalid.
    /// @custom:reverts If fulfillmentInfo not found at inboxContractStorageKey on request.inboxContract
    /// @custom:reverts If fulfillmentInfo.timestamp is less than request.finalityDelaySeconds from current destination
    /// chain block timestamp.
    /// @custom:reverts If the L2StateRoot does not correspond to the validated L1 storage slot
    ///
    /// @dev Implementation will vary by L2
    ///
    /// @param inboxContractStorageKey The storage location of the data to verify on the destination chain
    /// `RIP7755Inbox` contract
    /// @param request The original cross chain request submitted to this contract
    /// @param proof The proof to validate
    function _validateProof(
        bytes memory inboxContractStorageKey,
        CrossChainRequest calldata request,
        bytes calldata proof
    ) internal view override {
        OPStackProver.Target memory target = OPStackProver.Target({
            l1Address: request.l2Oracle,
            l1StorageKey: request.l2OracleStorageKey,
            l2Address: request.inboxContract,
            l2StorageKey: bytes32(inboxContractStorageKey)
        });
        (uint256 l2Timestamp, bytes memory inboxContractStorageValue) = proof.validate(target);

        RIP7755Inbox.FulfillmentInfo memory fulfillmentInfo = _decodeFulfillmentInfo(bytes32(inboxContractStorageValue));

        // Ensure that the fulfillment timestamp is not within the finality delay
        if (fulfillmentInfo.timestamp + request.finalityDelaySeconds > l2Timestamp) {
            revert FinalityDelaySecondsInProgress();
        }
    }
}
