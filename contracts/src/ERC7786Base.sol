// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title ERC7786Base
///
/// @author Coinbase (https://github.com/base-org/RIP-7755-poc)
///
/// @notice This contract contains the selectors for the RIP-7755-supported attributes of the ERC7786 standard
contract ERC7786Base {
    /// @notice A struct representing an individual call within a 7755 request
    struct Message {
        /// @dev The CAIP-10 account address of the receiver (not including the chain identifier)
        string receiver;
        /// @dev The calldata for the call to be made to the receiver
        bytes payload;
        /// @dev The attributes to be included in the message (should be empty)
        bytes[] attributes;
    }

    /// @notice Low-level call specs representing the desired transaction on destination chain
    struct Call {
        /// @dev The address to call
        bytes32 to;
        /// @dev The calldata to call with
        bytes data;
        /// @dev The native asset value of the call
        uint256 value;
    }

    /// @notice The selector for the precheck attribute
    bytes4 internal constant _PRECHECK_ATTRIBUTE_SELECTOR = 0xfa1e5831; // precheck(address)

    /// @notice The selector for the nonce attribute
    bytes4 internal constant _NONCE_ATTRIBUTE_SELECTOR = 0xce03fdab; // nonce(uint256)

    /// @notice The selector for the reward attribute
    bytes4 internal constant _REWARD_ATTRIBUTE_SELECTOR = 0xa362e5db; // reward(bytes32,uint256) rewardAsset, rewardAmount

    /// @notice The selector for the delay attribute
    bytes4 internal constant _DELAY_ATTRIBUTE_SELECTOR = 0x84f550e0; // delay(uint256,uint256) finalityDelaySeconds, expiry

    /// @notice The selector for the requester attribute
    bytes4 internal constant _REQUESTER_ATTRIBUTE_SELECTOR = 0x3bd94e4c; // requester(bytes32)

    /// @notice The selector for the l2Oracle attribute
    bytes4 internal constant _L2_ORACLE_ATTRIBUTE_SELECTOR = 0x7ff7245a; // l2Oracle(address)

    /// @notice The selector for the shoyuBashi attribute
    bytes4 internal constant _SHOYU_BASHI_ATTRIBUTE_SELECTOR = 0xda07e15d; // shoyuBashi(bytes32)

    /// @notice The selector for the inbox attribute
    bytes4 internal constant _INBOX_ATTRIBUTE_SELECTOR = 0xbd362374; // inbox(bytes32)

    /// @notice The selector for the destinationChain attribute
    bytes4 internal constant _DESTINATION_CHAIN_SELECTOR = 0xdff49bf1; // destinationChain(bytes32)

    /// @notice The selector for the isUserOp attribute. Used to designate a request designated to be a destination
    ///         chain ERC-4337 User Operation
    bytes4 internal constant _USER_OP_ATTRIBUTE_SELECTOR = 0xd45448dd; // isUserOp(bool)

    /// @notice This error is thrown if an attribute is not found in the attributes array
    ///
    /// @param selector The selector of the attribute that was not found
    error AttributeNotFound(bytes4 selector);

    /// @notice Locates an attribute in the attributes array
    ///
    /// @custom:reverts If the attribute is not found
    ///
    /// @param attributes The attributes array to search
    /// @param selector   The selector of the attribute to find
    ///
    /// @return attribute The attribute found
    function _locateAttribute(bytes[] calldata attributes, bytes4 selector) internal pure returns (bytes calldata) {
        (bool found, bytes calldata attribute) = _locateAttributeUnchecked(attributes, selector);

        if (!found) {
            revert AttributeNotFound(selector);
        }

        return attribute;
    }

    /// @notice Locates an attribute in the attributes array without checking if the attribute is found
    ///
    /// @param attributes The attributes array to search
    /// @param selector   The selector of the attribute to find
    ///
    /// @return found     Whether the attribute was found
    /// @return attribute The attribute found
    function _locateAttributeUnchecked(bytes[] calldata attributes, bytes4 selector)
        internal
        pure
        returns (bool found, bytes calldata attribute)
    {
        for (uint256 i; i < attributes.length; i++) {
            if (bytes4(attributes[i]) == selector) {
                return (true, attributes[i]);
            }
        }
        return (false, attributes[0]);
    }
}
