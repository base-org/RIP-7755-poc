// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {PackedUserOperation} from "account-abstraction/interfaces/PackedUserOperation.sol";

import {UserOpBase} from "./UserOpBase.s.sol";
import {HelperConfig} from "../HelperConfig.s.sol";

contract UserOpHashiBase is UserOpBase {
    bytes4 private constant _SHOYU_BASHI_ATTRIBUTE_SELECTOR = 0xda07e15d; // shoyuBashi(bytes32)
    bytes4 private constant _DESTINATION_CHAIN_SELECTOR = 0xdff49bf1; // destinationChain(bytes32)
    address private constant ENTRY_POINT = 0x0000000071727De22E5E9d8BAf0edAc6f37da032;

    function _initMessage(uint256 destinationChainId, uint256 duration, uint256 nonce, address shoyuBashi)
        internal
        returns (bytes32, bytes32, bytes memory, bytes[] memory)
    {
        (bytes32 destinationChain, bytes32 receiver, bytes memory payload, bytes[] memory baseAttributes) =
            _initMessage(destinationChainId, duration, nonce);

        PackedUserOperation memory userOp = abi.decode(payload, (PackedUserOperation));
        (address ethAddress, uint256 ethAmount, address precheck, bytes[] memory attributes) =
            abi.decode(_slice(userOp.paymasterAndData, 52), (address, uint256, address, bytes[]));

        bytes[] memory newAttributes = new bytes[](attributes.length + 1);

        for (uint256 i; i < attributes.length - 1; i++) {
            newAttributes[i] = attributes[i];
        }

        newAttributes[attributes.length - 1] = abi.encodeWithSelector(_SHOYU_BASHI_ATTRIBUTE_SELECTOR, shoyuBashi);
        newAttributes[attributes.length] = abi.encodeWithSelector(_DESTINATION_CHAIN_SELECTOR, destinationChain);

        userOp.paymasterAndData = _encodePaymasterAndData(
            _slice(userOp.paymasterAndData, 0, 52), ethAddress, ethAmount, precheck, newAttributes
        );

        return (destinationChain, receiver, abi.encode(userOp), baseAttributes);
    }

    function _encodePaymasterAndData(
        bytes memory prefix,
        address ethAddress,
        uint256 ethAmount,
        address precheck,
        bytes[] memory attributes
    ) private pure returns (bytes memory) {
        return abi.encodePacked(prefix, abi.encode(ethAddress, ethAmount, precheck, attributes));
    }

    // Including to block from coverage report
    function test_userOpHashi_base() external {}

    function _slice(bytes memory data, uint256 start, uint256 end) private pure returns (bytes memory) {
        bytes memory result = new bytes(end - start);
        for (uint256 i = start; i < end; i++) {
            result[i - start] = data[i];
        }
        return result;
    }

    function _slice(bytes memory data, uint256 start) private pure returns (bytes memory) {
        uint256 end = data.length;
        bytes memory result = new bytes(end - start);
        for (uint256 i = start; i < end; i++) {
            result[i - start] = data[i];
        }
        return result;
    }
}
