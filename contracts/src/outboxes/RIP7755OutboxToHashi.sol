// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {HashiProver} from "../libraries/provers/HashiProver.sol";
import {GlobalTypes} from "../libraries/GlobalTypes.sol";
import {RIP7755Inbox} from "../RIP7755Inbox.sol";
import {RIP7755Outbox} from "../RIP7755Outbox.sol";

/// @title RIP7755OutboxToHashi
///
/// @author Crosschain Alliance
///
/// @notice This contract implements storage proof validation to ensure that requested calls actually happened on a EVM chain.
contract RIP7755OutboxToHashi is RIP7755Outbox {
    using HashiProver for bytes;
    using GlobalTypes for bytes32;

    /// @notice This error is thrown when fulfillmentInfo.timestamp is less than request.finalityDelaySeconds from
    /// current destination chain block timestamp.
    error FinalityDelaySecondsInProgress();

    /// @notice Validates storage proofs and verifies fulfillment
    ///
    /// @custom:reverts If storage proof invalid.
    /// @custom:reverts If fulfillmentInfo.timestamp is less than request.finalityDelaySeconds from current destination
    /// chain block timestamp.
    /// @custom:reverts If the L2StateRoot does not correspond to the validated L1 storage slot
    ///
    /// @param inboxContractStorageKey The storage location of the data to verify on the destination chain
    /// `RIP7755Inbox` contract
    /// @param inbox The address of the `RIP7755Inbox` contract
    /// @param attributes The attributes of the message
    /// @param proof The proof to validate
    function _validateProof(
        bytes memory inboxContractStorageKey,
        address inbox,
        bytes[] calldata attributes,
        bytes calldata proof
    ) internal view override {
        uint256 destinationChainId = _extractChainId(attributes);

        /// @notice The ShoyuBashi check should be performed within the PrecheckContract to ensure the correct ShoyuBashi is being used.
        address shoyuBashi = _extractShoyuBashi(attributes);
        HashiProver.Target memory target = HashiProver.Target({
            addr: inbox,
            storageKey: inboxContractStorageKey,
            destinationChainId: destinationChainId,
            shoyuBashi: shoyuBashi
        });
        (uint256 timestamp, bytes memory inboxContractStorageValue) = proof.validate(target);

        RIP7755Inbox.FulfillmentInfo memory fulfillmentInfo = _decodeFulfillmentInfo(bytes32(inboxContractStorageValue));

        bytes calldata delayAttribute = _locateAttribute(attributes, _DELAY_ATTRIBUTE_SELECTOR);
        (uint256 delaySeconds,) = abi.decode(delayAttribute[4:], (uint256, uint256));

        // Ensure that the fulfillment timestamp is not within the finality delay
        if (fulfillmentInfo.timestamp + delaySeconds > timestamp) {
            revert FinalityDelaySecondsInProgress();
        }
    }

    function _extractChainId(bytes[] calldata attributes) internal pure returns (uint256) {
        bytes calldata destinationChainAttribute = _locateAttribute(attributes, _DESTINATION_CHAIN_SELECTOR);
        bytes32 destinationChainBytes32 = abi.decode(destinationChainAttribute[4:], (bytes32));
        uint256 destinationChainId = uint256(destinationChainBytes32);
        return destinationChainId;
    }

    function _extractShoyuBashi(bytes[] calldata attributes) internal pure returns (address) {
        bytes calldata shoyuBashiBytes = _locateAttribute(attributes, _SHOYU_BASHI_ATTRIBUTE_SELECTOR);
        bytes32 shoyuBashiBytes32 = abi.decode(shoyuBashiBytes[4:], (bytes32));
        return shoyuBashiBytes32.bytes32ToAddress();
    }
}
