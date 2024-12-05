// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {ArbitrumProver} from "../libraries/provers/ArbitrumProver.sol";
import {GlobalTypes} from "../libraries/GlobalTypes.sol";
import {RIP7755Inbox} from "../RIP7755Inbox.sol";
import {RIP7755Outbox} from "../RIP7755Outbox.sol";
import {CrossChainRequest} from "../RIP7755Structs.sol";

/// @title RIP7755OutboxToArbitrum
///
/// @author Coinbase (https://github.com/base-org/RIP-7755-poc)
///
/// @notice This contract implements storage proof validation to ensure that requested calls actually happened on Arbitrum
contract RIP7755OutboxToArbitrum is RIP7755Outbox {
    using ArbitrumProver for bytes;
    using GlobalTypes for bytes32;

    /// @notice This error is thrown when fulfillmentInfo.timestamp is less than request.finalityDelaySeconds from
    /// current destination chain block timestamp.
    error FinalityDelaySecondsInProgress();

    /// @notice Validates storage proofs and verifies fulfillment
    ///
    /// @custom:reverts If storage proof invalid.
    /// @custom:reverts If fulfillmentInfo not found at verifyingContractStorageKey on request.verifyingContract
    /// @custom:reverts If fulfillmentInfo.timestamp is less than request.finalityDelaySeconds from current destination
    /// chain block timestamp.
    /// @custom:reverts If the L2StorageRoot does not correspond to our validated L1 storage slot
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
        ArbitrumProver.Target memory target = ArbitrumProver.Target({
            l1Address: request.l2Oracle.bytes32ToAddress(),
            l2Address: request.inboxContract.bytes32ToAddress(),
            l2StorageKey: inboxContractStorageKey
        });
        (uint256 l2Timestamp, bytes memory inboxContractStorageValue) = proof.validate(target);

        RIP7755Inbox.FulfillmentInfo memory fulfillmentInfo = _decodeFulfillmentInfo(bytes32(inboxContractStorageValue));

        // Ensure that the fulfillment timestamp is not within the finality delay
        if (fulfillmentInfo.timestamp + request.finalityDelaySeconds > l2Timestamp) {
            revert FinalityDelaySecondsInProgress();
        }
    }
}
