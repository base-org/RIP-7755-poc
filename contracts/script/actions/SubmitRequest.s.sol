// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script} from "forge-std/Script.sol";

import {GlobalTypes} from "../../src/libraries/GlobalTypes.sol";
import {RRC7755Base} from "../../src/RRC7755Base.sol";
import {RRC7755Outbox} from "../../src/RRC7755Outbox.sol";
import {HelperConfig} from "../HelperConfig.s.sol";

contract SubmitRequest is Script, RRC7755Base {
    using GlobalTypes for address;

    bytes4 internal constant _REWARD_ATTRIBUTE_SELECTOR = 0xa362e5db; // reward(bytes32,uint256) rewardAsset, rewardAmount
    bytes4 internal constant _DELAY_ATTRIBUTE_SELECTOR = 0x84f550e0; // delay(uint256,uint256) finalityDelaySeconds, expiry
    bytes4 internal constant _L2_ORACLE_ATTRIBUTE_SELECTOR = 0x7ff7245a; // l2Oracle(address)
    bytes4 internal constant _SHOYU_BASHI_ATTRIBUTE_SELECTOR = 0xda07e15d; // shoyuBashi(bytes32)
    bytes4 internal constant _DESTINATION_CHAIN_SELECTOR = 0xdff49bf1; // destinationChain(bytes32)
    bytes32 private constant _NATIVE_ASSET = 0x000000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee;

    HelperConfig public helperConfig;

    constructor() {
        helperConfig = new HelperConfig();
    }

    function run() external {
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig(block.chainid);

        address outboxAddr = config.opStackOutbox;
        uint256 destinationChainId = helperConfig.BASE_SEPOLIA_CHAIN_ID();
        uint256 duration = 1 weeks;

        RRC7755Outbox outbox = RRC7755Outbox(outboxAddr);

        (bytes32 destinationChain, bytes32 receiver, Call[] memory calls, bytes[] memory attributes) =
            _initMessage(destinationChainId, duration);

        vm.startBroadcast(config.deployerKey);
        outbox.sendMessage{value: 0.0002 ether}(destinationChain, receiver, abi.encode(calls), attributes);
        vm.stopBroadcast();
    }

    function _initMessage(uint256 destinationChainId, uint256 duration)
        private
        returns (bytes32, bytes32, Call[] memory, bytes[] memory)
    {
        HelperConfig.NetworkConfig memory dstConfig = helperConfig.getConfig(destinationChainId);
        // HelperConfig.NetworkConfig memory srcConfig = helperConfig.getConfig(block.chainid);

        Call[] memory calls = new Call[](1);
        calls[0] =
            Call({to: 0x8C1a617BdB47342F9C17Ac8750E0b070c372C721.addressToBytes32(), data: "", value: 0.0001 ether});

        bytes32 destinationChain = bytes32(destinationChainId);
        bytes32 receiver = dstConfig.inbox.addressToBytes32();
        bytes[] memory attributes = new bytes[](3);

        attributes[0] = abi.encodeWithSelector(_REWARD_ATTRIBUTE_SELECTOR, _NATIVE_ASSET, 0.0002 ether);
        attributes[1] = abi.encodeWithSelector(_DELAY_ATTRIBUTE_SELECTOR, duration, block.timestamp + 2 weeks);
        attributes[2] = abi.encodeWithSelector(_L2_ORACLE_ATTRIBUTE_SELECTOR, dstConfig.l2Oracle);
        // attributes[2] = abi.encodeWithSelector(_SHOYU_BASHI_ATTRIBUTE_SELECTOR, srcConfig.shoyuBashi);
        // attributes[3] = abi.encodeWithSelector(_DESTINATION_CHAIN_SELECTOR, destinationChain);

        return (destinationChain, receiver, calls, attributes);
    }

    // Including to block from coverage report
    function test() external {}
}
