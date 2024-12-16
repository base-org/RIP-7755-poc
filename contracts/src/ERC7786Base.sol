// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract ERC7786Base {
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

    /// @notice The selector for the fulfiller attribute
    bytes4 internal constant _FULFILLER_ATTRIBUTE_SELECTOR = 0x138a03fc; // fulfiller(address)

    /// @notice The selector for the l2Oracle attribute
    bytes4 internal constant _L2_ORACLE_ATTRIBUTE_SELECTOR = 0x7ff7245a; // l2Oracle(address)

    /// @notice This error is thrown if an attribute is not found in the attributes array
    /// @param selector The selector of the attribute that was not found
    error AttributeNotFound(bytes4 selector);

    function _locateAttribute(bytes[] calldata attributes, bytes4 selector) internal pure returns (bytes calldata) {
        (bool found, bytes calldata attribute) = _locateAttributeUnchecked(attributes, selector);

        if (!found) {
            revert AttributeNotFound(selector);
        }

        return attribute;
    }

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
