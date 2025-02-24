// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {RRC7755Outbox} from "../../src/RRC7755Outbox.sol";

contract MockOutbox is RRC7755Outbox {
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

        bool[4] memory attributeProcessed = [false, false, false, false];

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
    }

    function _minExpiryTime(uint256) internal pure override returns (uint256) {
        return 10;
    }

    function _validateProof(
        bytes memory inboxContractStorageKey,
        address inbox,
        bytes[] calldata attributes,
        bytes calldata proofData
    ) internal view override {}

    // Including to block from coverage report
    function test() external {}
}
