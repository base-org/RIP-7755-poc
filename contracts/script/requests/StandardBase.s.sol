// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script} from "forge-std/Script.sol";

import {GlobalTypes} from "../../src/libraries/GlobalTypes.sol";
import {RRC7755Base} from "../../src/RRC7755Base.sol";
import {RRC7755Outbox} from "../../src/RRC7755Outbox.sol";
import {HelperConfig} from "../HelperConfig.s.sol";

contract StandardBase is Script, RRC7755Base {
    using GlobalTypes for address;

    address internal constant _REQUESTER = 0x8C1a617BdB47342F9C17Ac8750E0b070c372C721;

    bytes4 private constant _REWARD_ATTRIBUTE_SELECTOR = 0xa362e5db; // reward(bytes32,uint256) rewardAsset, rewardAmount
    bytes4 private constant _DELAY_ATTRIBUTE_SELECTOR = 0x84f550e0; // delay(uint256,uint256) finalityDelaySeconds, expiry
    bytes4 private constant _L2_ORACLE_ATTRIBUTE_SELECTOR = 0x7ff7245a; // l2Oracle(address)
    bytes4 private constant _NONCE_ATTRIBUTE_SELECTOR = 0xce03fdab; // nonce(uint256)
    bytes4 private constant _REQUESTER_ATTRIBUTE_SELECTOR = 0x3bd94e4c; // requester(bytes32)
    bytes32 private constant _NATIVE_ASSET = 0x000000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee;

    HelperConfig internal helperConfig;

    constructor() {
        helperConfig = new HelperConfig();
    }

    function _initMessage(uint256 destinationChainId, uint256 duration, uint256 nonce)
        internal
        virtual
        returns (bytes32, bytes32, bytes memory, bytes[] memory)
    {
        HelperConfig.NetworkConfig memory dstConfig = helperConfig.getConfig(destinationChainId);

        Call[] memory calls = new Call[](1);
        calls[0] = Call({to: _REQUESTER.addressToBytes32(), data: "", value: 0.0001 ether});

        bytes32 destinationChain = bytes32(destinationChainId);
        bytes32 receiver = dstConfig.inbox.addressToBytes32();
        bytes[] memory attributes = new bytes[](5);

        attributes[0] = abi.encodeWithSelector(_REWARD_ATTRIBUTE_SELECTOR, _NATIVE_ASSET, 0.0002 ether);
        attributes[1] = abi.encodeWithSelector(_DELAY_ATTRIBUTE_SELECTOR, duration, block.timestamp + 2 weeks);
        attributes[2] = abi.encodeWithSelector(_NONCE_ATTRIBUTE_SELECTOR, nonce);
        attributes[3] = abi.encodeWithSelector(_REQUESTER_ATTRIBUTE_SELECTOR, _REQUESTER.addressToBytes32());
        attributes[4] = abi.encodeWithSelector(_L2_ORACLE_ATTRIBUTE_SELECTOR, dstConfig.l2Oracle);

        return (destinationChain, receiver, abi.encode(calls), attributes);
    }

    // Including to block from coverage report
    function test_base() external {}
}
