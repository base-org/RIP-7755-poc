// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title ERC7786Base
///
/// @author Coinbase (https://github.com/base-org/RRC-7755-poc)
///
/// @notice This contract contains the selectors for the RRC-7755-supported attributes of the ERC7786 standard
contract RRC7755Base {
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
    bytes4 internal constant _PRECHECK_ATTRIBUTE_SELECTOR = 0xbef86027; // precheck(bytes32)

    /// @notice This error is thrown if an attribute is not found in the attributes array
    ///
    /// @param selector The selector of the attribute that was not found
    error AttributeNotFound(bytes4 selector);

    /// @notice Returns the keccak256 hash of a message request
    ///
    /// @dev Filters out the fulfiller attribute from the attributes array
    ///
    /// @param sourceChain      The source chain identifier
    /// @param sender           The account address of the sender
    /// @param destinationChain The destination chain identifier
    /// @param receiver         The account address of the receiver
    /// @param payload          The encoded calls to be included in the request
    /// @param attributes       The attributes to be included in the message
    ///
    /// @return _ The keccak256 hash of the message request
    function getRequestId(
        bytes32 sourceChain,
        bytes32 sender,
        bytes32 destinationChain,
        bytes32 receiver,
        bytes calldata payload,
        bytes[] calldata attributes
    ) public view virtual returns (bytes32) {
        return keccak256(abi.encode(sourceChain, sender, destinationChain, receiver, payload, attributes));
    }

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
