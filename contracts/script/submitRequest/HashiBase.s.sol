// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {HelperConfig} from "../HelperConfig.s.sol";
import {StandardBase} from "../requests/StandardBase.s.sol";

contract HashiBase is StandardBase {
    bytes4 private constant _SHOYU_BASHI_ATTRIBUTE_SELECTOR = 0xda07e15d; // shoyuBashi(bytes32)
    bytes4 private constant _DESTINATION_CHAIN_SELECTOR = 0xdff49bf1; // destinationChain(bytes32)

    function _initMessage(uint256 destinationChainId, uint256 duration, uint256 nonce)
        internal
        override
        returns (bytes32, bytes32, bytes memory, bytes[] memory)
    {
        (bytes32 destinationChain, bytes32 receiver, bytes memory payload, bytes[] memory attributes) =
            super._initMessage(destinationChainId, duration, nonce);
        HelperConfig.NetworkConfig memory srcConfig = helperConfig.getConfig(block.chainid);

        bytes[] memory newAttributes = new bytes[](attributes.length + 1);

        for (uint256 i; i < attributes.length - 1; i++) {
            newAttributes[i] = attributes[i];
        }

        newAttributes[attributes.length - 1] =
            abi.encodeWithSelector(_SHOYU_BASHI_ATTRIBUTE_SELECTOR, srcConfig.shoyuBashi);
        newAttributes[attributes.length] = abi.encodeWithSelector(_DESTINATION_CHAIN_SELECTOR, destinationChain);

        return (destinationChain, receiver, payload, newAttributes);
    }

    // Including to block from coverage report
    function test_hashi_base() external {}
}
