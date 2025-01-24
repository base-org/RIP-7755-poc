// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {ArbitrumProver} from "../libraries/provers/ArbitrumProver.sol";
import {RIP7755Inbox} from "../RIP7755Inbox.sol";
import {RIP7755Outbox} from "../RIP7755Outbox.sol";

/// @title RIP7755OutboxToArbitrum
///
/// @author Coinbase (https://github.com/base-org/RIP-7755-poc)
///
/// @notice This contract implements storage proof validation to ensure that requested calls actually happened on Arbitrum
contract RIP7755OutboxToArbitrum is RIP7755Outbox {
    using ArbitrumProver for bytes;

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
    /// @param inbox The address of the `RIP7755Inbox` contract
    /// @param attributes The attributes of the request
    /// @param proof The proof to validate
    function _validateProof(
        bytes memory inboxContractStorageKey,
        address inbox,
        bytes[] calldata attributes,
        bytes calldata proof
    ) internal view override {
        bytes calldata l2OracleAttribute = _locateAttribute(attributes, _L2_ORACLE_ATTRIBUTE_SELECTOR);
        address l2Oracle = abi.decode(l2OracleAttribute[4:], (address));

        ArbitrumProver.Target memory target =
            ArbitrumProver.Target({l1Address: l2Oracle, l2Address: inbox, l2StorageKey: inboxContractStorageKey});
        (uint256 l2Timestamp, bytes memory inboxContractStorageValue) = proof.validate(target);

        RIP7755Inbox.FulfillmentInfo memory fulfillmentInfo = _decodeFulfillmentInfo(bytes32(inboxContractStorageValue));

        bytes calldata delayAttribute = _locateAttribute(attributes, _DELAY_ATTRIBUTE_SELECTOR);
        (uint256 delaySeconds,) = abi.decode(delayAttribute[4:], (uint256, uint256));

        // Ensure that the fulfillment timestamp is not within the finality delay
        if (fulfillmentInfo.timestamp + delaySeconds > l2Timestamp) {
            revert FinalityDelaySecondsInProgress();
        }
    }
}
