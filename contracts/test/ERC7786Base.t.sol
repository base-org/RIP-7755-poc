// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {BaseTest} from "./BaseTest.t.sol";

contract ERC7786BaseTest is BaseTest {
    function test_locateAttribute_returnsAttribute() external view {
        bytes[] memory attributes = new bytes[](1);
        attributes[0] = abi.encodeWithSelector(_DESTINATION_CHAIN_SELECTOR, FILLER);
        bytes memory returnedAttribute = this.submitAttributes(attributes, _DESTINATION_CHAIN_SELECTOR);
        assertEq(returnedAttribute, attributes[0]);
    }

    function test_locateAttribute_revertsIfAttributeNotFound() external {
        bytes[] memory attributes = new bytes[](1);
        attributes[0] = abi.encodeWithSelector(_DESTINATION_CHAIN_SELECTOR, FILLER);
        vm.expectRevert(abi.encodeWithSelector(AttributeNotFound.selector, _PRECHECK_ATTRIBUTE_SELECTOR));
        this.submitAttributes(attributes, _PRECHECK_ATTRIBUTE_SELECTOR);
    }

    function test_locateAttributeUnchecked_returnsAttribute() external view {
        bytes[] memory attributes = new bytes[](1);
        attributes[0] = abi.encodeWithSelector(_DESTINATION_CHAIN_SELECTOR, FILLER);
        (bool found, bytes memory returnedAttribute) =
            this.locateAttributeUnchecked(attributes, _DESTINATION_CHAIN_SELECTOR);
        assertTrue(found);
        assertEq(returnedAttribute, attributes[0]);
    }

    function test_locateAttributeUnchecked_returnsFalseIfAttributeNotFound() external view {
        bytes[] memory attributes = new bytes[](1);
        attributes[0] = abi.encodeWithSelector(_DESTINATION_CHAIN_SELECTOR, FILLER);
        (bool found, bytes memory returnedAttribute) =
            this.locateAttributeUnchecked(attributes, _PRECHECK_ATTRIBUTE_SELECTOR);
        assertFalse(found);
        assertEq(returnedAttribute, attributes[0]);
    }

    function submitAttributes(bytes[] calldata attributes, bytes4 selector) public pure returns (bytes calldata) {
        return _locateAttribute(attributes, selector);
    }

    function locateAttributeUnchecked(bytes[] calldata attributes, bytes4 selector)
        public
        pure
        returns (bool, bytes calldata)
    {
        return _locateAttributeUnchecked(attributes, selector);
    }
}
