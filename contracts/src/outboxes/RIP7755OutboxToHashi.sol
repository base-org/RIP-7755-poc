// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {IShoyuBashi} from "../interfaces/IShoyuBashi.sol";
import {HashiProver} from "../libraries/provers/HashiProver.sol";
import {GlobalTypes} from "../libraries/GlobalTypes.sol";
import {RIP7755Inbox} from "../RIP7755Inbox.sol";
import {RIP7755Outbox} from "../RIP7755Outbox.sol";
import {CrossChainRequest} from "../RIP7755Structs.sol";

/// @title RIP7755OutboxToHashi
///
/// @author Crosschain Alliance
///
/// @notice This contract implements storage proof validation to ensure that requested calls actually happened on a EVM chain.
contract RIP7755OutboxToHashi is RIP7755Outbox {
    using HashiProver for bytes;
    using GlobalTypes for bytes32;

    /// @notice The expected length of the request.extraData field as a constant
    uint256 private constant EXPECTED_EXTRA_DATA_LENGTH = 2;

    /// @notice This error is thrown when fulfillmentInfo.timestamp is less than request.finalityDelaySeconds from
    /// current destination chain block timestamp.
    error FinalityDelaySecondsInProgress();

    /// @notice This error is thrown when the request.extraData field has an invalid length
    error InvalidExtraDataLength();

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
    ) internal view {
        if (request.extraData.length != EXPECTED_EXTRA_DATA_LENGTH) revert InvalidExtraDataLength();
        /// @notice The ShoyuBashi check should be performed within the PrecheckContract to ensure the correct ShoyuBashi is being used.
        (address shoyuBashi) = abi.decode(request.extraData[1], (address));
        HashiProver.Target memory target = HashiProver.Target({
            addr: request.inboxContract.bytes32ToAddress(),
            storageKey: inboxContractStorageKey,
            destinationChainId: request.destinationChainId,
            shoyuBashi: shoyuBashi
        });
        (uint256 timestamp, bytes memory inboxContractStorageValue) = proof.validate(target);

        RIP7755Inbox.FulfillmentInfo memory fulfillmentInfo = _decodeFulfillmentInfo(bytes32(inboxContractStorageValue));

        // Ensure that the fulfillment timestamp is not within the finality delay
        if (fulfillmentInfo.timestamp + request.finalityDelaySeconds > timestamp) {
            revert FinalityDelaySecondsInProgress();
        }
    }

    function _validateProof2(
        bytes memory inboxContractStorageKey,
        bytes[] calldata attributes,
        bytes calldata proofData
    ) internal view override {}
}
