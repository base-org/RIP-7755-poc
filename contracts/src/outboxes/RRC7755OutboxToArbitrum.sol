// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {ArbitrumProver} from "../libraries/provers/ArbitrumProver.sol";
import {RRC7755Outbox} from "../RRC7755Outbox.sol";

/// @title RRC7755OutboxToArbitrum
///
/// @author Coinbase (https://github.com/base/RRC-7755-poc)
///
/// @notice This contract implements storage proof validation to ensure that requested calls actually happened on
///         Arbitrum
contract RRC7755OutboxToArbitrum is RRC7755Outbox {
    using ArbitrumProver for bytes;

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

        bool[5] memory attributeProcessed;

        for (uint256 i; i < attributes.length; i++) {
            bytes4 attributeSelector = bytes4(attributes[i]);

            if (attributeSelector == _REWARD_ATTRIBUTE_SELECTOR && !attributeProcessed[0]) {
                _handleRewardAttribute(attributes[i], requester, value);
                attributeProcessed[0] = true;
            } else if (attributeSelector == _L2_ORACLE_ATTRIBUTE_SELECTOR && !attributeProcessed[1]) {
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
            } else if (attributeSelector == _DELAY_ATTRIBUTE_SELECTOR && !attributeProcessed[4]) {
                _handleDelayAttribute(attributes[i]);
                attributeProcessed[4] = true;
            } else if (!_isOptionalAttribute(attributeSelector)) {
                revert UnsupportedAttribute(attributeSelector);
            }
        }

        if (!attributeProcessed[0]) {
            revert MissingRequiredAttribute(_REWARD_ATTRIBUTE_SELECTOR);
        }

        if (!attributeProcessed[1]) {
            revert MissingRequiredAttribute(_L2_ORACLE_ATTRIBUTE_SELECTOR);
        }

        if (!attributeProcessed[2]) {
            revert MissingRequiredAttribute(_NONCE_ATTRIBUTE_SELECTOR);
        }

        if (!attributeProcessed[3]) {
            revert MissingRequiredAttribute(_REQUESTER_ATTRIBUTE_SELECTOR);
        }

        if (!attributeProcessed[4]) {
            revert MissingRequiredAttribute(_DELAY_ATTRIBUTE_SELECTOR);
        }
    }

    // function processAttributes(bytes[] calldata attributes, address requester, uint256 value) public override {
    //     if (msg.sender != address(this)) {
    //         revert InvalidCaller({caller: msg.sender, expectedCaller: address(this)});
    //     }

    //     // Define required attributes and their handlers
    //     bytes4[5] memory requiredSelectors = [
    //         _REWARD_ATTRIBUTE_SELECTOR,
    //         _L2_ORACLE_ATTRIBUTE_SELECTOR,
    //         _NONCE_ATTRIBUTE_SELECTOR,
    //         _REQUESTER_ATTRIBUTE_SELECTOR,
    //         _DELAY_ATTRIBUTE_SELECTOR
    //     ];
    //     bool[5] memory processed;

    //     // Process all attributes
    //     for (uint256 i; i < attributes.length; i++) {
    //         bytes4 selector = bytes4(attributes[i]);

    //         uint256 index = _findSelectorIndex(selector, requiredSelectors);
    //         if (index != type(uint256).max) {
    //             if (processed[index]) continue; // Skip if already processed

    //             _processAttribute(selector, attributes[i], requester, value);
    //             processed[index] = true;
    //         } else if (!_isOptionalAttribute(selector)) {
    //             revert UnsupportedAttribute(selector);
    //         }
    //     }

    //     // Check for missing required attributes
    //     for (uint256 i; i < requiredSelectors.length; i++) {
    //         if (!processed[i]) {
    //             revert MissingRequiredAttribute(requiredSelectors[i]);
    //         }
    //     }
    // }

    /// @notice Returns true if the attribute selector is supported by this contract
    ///
    /// @param selector The selector of the attribute
    ///
    /// @return _ True if the attribute selector is supported by this contract
    function supportsAttribute(bytes4 selector) public pure override returns (bool) {
        return selector == _REWARD_ATTRIBUTE_SELECTOR || selector == _L2_ORACLE_ATTRIBUTE_SELECTOR
            || selector == _NONCE_ATTRIBUTE_SELECTOR || selector == _REQUESTER_ATTRIBUTE_SELECTOR
            || selector == _DELAY_ATTRIBUTE_SELECTOR || super.supportsAttribute(selector);
    }

    /// @notice Returns the minimum amount of time before a request can expire
    function _minExpiryTime(uint256) internal pure override returns (uint256) {
        return 8 days;
    }

    /// @notice Validates storage proofs and verifies fulfillment
    ///
    /// @custom:reverts If storage proof invalid.
    /// @custom:reverts If fulfillmentInfo not found at verifyingContractStorageKey on request.verifyingContract
    /// @custom:reverts If the L2StorageRoot does not correspond to our validated L1 storage slot
    ///
    /// @param inboxContractStorageKey The storage location of the data to verify on the destination chain
    ///                                `RRC7755Inbox` contract
    /// @param inbox                   The address of the `RRC7755Inbox` contract
    /// @param attributes              The attributes of the request
    /// @param proof                   The proof to validate
    function _validateProof(
        bytes memory inboxContractStorageKey,
        address inbox,
        bytes[] calldata attributes,
        bytes calldata proof
    ) internal view override {
        bytes calldata l2OracleAttribute = _locateAttribute(attributes, _L2_ORACLE_ATTRIBUTE_SELECTOR);
        address l2Oracle = abi.decode(l2OracleAttribute[4:], (address));
        proof.validate(
            ArbitrumProver.Target({l1Address: l2Oracle, l2Address: inbox, l2StorageKey: inboxContractStorageKey})
        );
    }

    // /// @dev Helper function to process individual attributes
    // function _processAttribute(bytes4 selector, bytes calldata attribute, address requester, uint256 value) private {
    //     if (selector == _REWARD_ATTRIBUTE_SELECTOR) {
    //         _handleRewardAttribute(attribute, requester, value);
    //     } else if (selector == _L2_ORACLE_ATTRIBUTE_SELECTOR) {
    //         // No processing needed
    //     } else if (selector == _NONCE_ATTRIBUTE_SELECTOR) {
    //         if (abi.decode(attribute[4:], (uint256)) != _incrementNonce(requester)) {
    //             revert InvalidNonce();
    //         }
    //     } else if (selector == _REQUESTER_ATTRIBUTE_SELECTOR) {
    //         if (abi.decode(attribute[4:], (address)) != requester) {
    //             revert InvalidRequester();
    //         }
    //     } else if (selector == _DELAY_ATTRIBUTE_SELECTOR) {
    //         _handleDelayAttribute(attribute);
    //     }
    // }

    // /// @dev Helper function to find the index of a selector in the array
    // function _findSelectorIndex(bytes4 selector, bytes4[5] memory selectors) private pure returns (uint256) {
    //     for (uint256 i; i < selectors.length; i++) {
    //         if (selector == selectors[i]) return i;
    //     }
    //     return type(uint256).max; // Not found
    // }
}
