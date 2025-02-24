// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {HashiProver} from "../libraries/provers/HashiProver.sol";
import {GlobalTypes} from "../libraries/GlobalTypes.sol";
import {RRC7755Inbox} from "../RRC7755Inbox.sol";
import {RRC7755Outbox} from "../RRC7755Outbox.sol";

/// @title RRC7755OutboxToHashi
///
/// @author Crosschain Alliance
///
/// @notice This contract implements storage proof validation to ensure that requested calls actually happened on a EVM
///         chain.
contract RRC7755OutboxToHashi is RRC7755Outbox {
    using HashiProver for bytes;
    using GlobalTypes for bytes32;

    /// @notice The selector for the shoyuBashi attribute
    bytes4 internal constant _SHOYU_BASHI_ATTRIBUTE_SELECTOR = 0xda07e15d; // shoyuBashi(bytes32)

    /// @notice The selector for the destinationChain attribute
    bytes4 internal constant _DESTINATION_CHAIN_SELECTOR = 0xdff49bf1; // destinationChain(bytes32)

    /// @notice This error is thrown when fulfillmentInfo.timestamp is less than request.finalityDelaySeconds from
    ///         current destination chain block timestamp.
    error FinalityDelaySecondsInProgress();

    /// @notice This is only to be called by this contract during a `sendMessage` call
    ///
    /// @custom:reverts If the caller is not this contract
    ///
    /// @param attributes The attributes to be processed
    /// @param requester  The address of the requester
    /// @param value      The value of the message
    function processAttributes(bytes[] calldata attributes, address requester, uint256 value) public override {
        if (msg.sender != address(this)) {
            revert InvalidCaller({caller: msg.sender, expectedCaller: address(this)});
        }

        bool[6] memory attributeProcessed = [false, false, false, false, false, false];

        for (uint256 i; i < attributes.length; i++) {
            bytes4 attributeSelector = bytes4(attributes[i]);

            if (attributeSelector == _REWARD_ATTRIBUTE_SELECTOR && !attributeProcessed[0]) {
                _handleRewardAttribute(attributes[i], requester, value);
                attributeProcessed[0] = true;
            } else if (attributeSelector == _DELAY_ATTRIBUTE_SELECTOR && !attributeProcessed[1]) {
                _handleDelayAttribute(attributes[i]);
                attributeProcessed[1] = true;
            } else if (attributeSelector == _NONCE_ATTRIBUTE_SELECTOR && !attributeProcessed[2]) {
                // confirm passed in nonce == _incrementNonce()
                if (abi.decode(attributes[i][4:], (uint256)) != _incrementNonce(requester)) {
                    revert InvalidNonce();
                }
                attributeProcessed[2] = true;
            } else if (attributeSelector == _REQUESTER_ATTRIBUTE_SELECTOR && !attributeProcessed[3]) {
                // confirm passed in requester == msg.sender
                if (abi.decode(attributes[i][4:], (address)) != requester) {
                    revert InvalidRequester();
                }
                attributeProcessed[3] = true;
            } else if (attributeSelector == _SHOYU_BASHI_ATTRIBUTE_SELECTOR && !attributeProcessed[4]) {
                attributeProcessed[4] = true;
            } else if (attributeSelector == _DESTINATION_CHAIN_SELECTOR && !attributeProcessed[5]) {
                attributeProcessed[5] = true;
            } else if (!_isOptionalAttribute(attributeSelector)) {
                revert UnsupportedAttribute(attributeSelector);
            }
        }

        if (!attributeProcessed[0]) {
            revert MissingRequiredAttribute(_REWARD_ATTRIBUTE_SELECTOR);
        }

        if (!attributeProcessed[1]) {
            revert MissingRequiredAttribute(_DELAY_ATTRIBUTE_SELECTOR);
        }

        if (!attributeProcessed[2]) {
            revert MissingRequiredAttribute(_NONCE_ATTRIBUTE_SELECTOR);
        }

        if (!attributeProcessed[3]) {
            revert MissingRequiredAttribute(_REQUESTER_ATTRIBUTE_SELECTOR);
        }

        if (!attributeProcessed[4]) {
            revert MissingRequiredAttribute(_SHOYU_BASHI_ATTRIBUTE_SELECTOR);
        }

        if (!attributeProcessed[5]) {
            revert MissingRequiredAttribute(_DESTINATION_CHAIN_SELECTOR);
        }
    }

    /// @notice Returns true if the attribute selector is supported by this contract
    ///
    /// @param selector The selector of the attribute
    ///
    /// @return _ True if the attribute selector is supported by this contract
    function supportsAttribute(bytes4 selector) public pure override returns (bool) {
        return selector == _REWARD_ATTRIBUTE_SELECTOR || selector == _DELAY_ATTRIBUTE_SELECTOR
            || selector == _NONCE_ATTRIBUTE_SELECTOR || selector == _REQUESTER_ATTRIBUTE_SELECTOR
            || selector == _SHOYU_BASHI_ATTRIBUTE_SELECTOR || selector == _DESTINATION_CHAIN_SELECTOR
            || super.supportsAttribute(selector);
    }

    /// @notice Returns the minimum amount of time before a request can expire
    function _minExpiryTime(uint256 finalityDelaySeconds) internal pure override returns (uint256) {
        return finalityDelaySeconds;
    }

    /// @notice Validates storage proofs and verifies fulfillment
    ///
    /// @custom:reverts If storage proof invalid.
    /// @custom:reverts If fulfillmentInfo.timestamp is less than request.finalityDelaySeconds from current destination
    ///                 chain block timestamp.
    /// @custom:reverts If the L2StateRoot does not correspond to the validated L1 storage slot
    ///
    /// @param inboxContractStorageKey The storage location of the data to verify on the destination chain
    ///                                `RRC7755Inbox` contract
    /// @param inbox                   The address of the `RRC7755Inbox` contract
    /// @param attributes              The attributes of the message
    /// @param proof                   The proof to validate
    function _validateProof(
        bytes memory inboxContractStorageKey,
        address inbox,
        bytes[] calldata attributes,
        bytes calldata proof
    ) internal view override {
        uint256 destinationChainId = _extractChainId(attributes);

        address shoyuBashi = _extractShoyuBashi(attributes);
        HashiProver.Target memory target = HashiProver.Target({
            addr: inbox,
            storageKey: inboxContractStorageKey,
            destinationChainId: destinationChainId,
            shoyuBashi: shoyuBashi
        });
        (uint256 timestamp, bytes memory inboxContractStorageValue) = proof.validate(target);

        RRC7755Inbox.FulfillmentInfo memory fulfillmentInfo = _decodeFulfillmentInfo(bytes32(inboxContractStorageValue));

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
