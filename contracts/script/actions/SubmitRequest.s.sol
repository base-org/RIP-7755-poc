// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script} from "forge-std/Script.sol";

import {GlobalTypes} from "../../src/libraries/GlobalTypes.sol";
import {ERC7786Base} from "../../src/ERC7786Base.sol";
import {RIP7755Outbox} from "../../src/RIP7755Outbox.sol";
import {HelperConfig} from "../HelperConfig.s.sol";

contract SubmitRequest is Script, ERC7786Base {
    using GlobalTypes for address;

    HelperConfig public helperConfig;

    bytes32 private constant _NATIVE_ASSET = 0x000000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee;

    constructor() {
        helperConfig = new HelperConfig();
    }

    function run() external {
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig(block.chainid);

        address outboxAddr = config.opStackOutbox;
        uint256 destinationChainId = helperConfig.BASE_SEPOLIA_CHAIN_ID();
        uint256 duration = 1 weeks;

        RIP7755Outbox outbox = RIP7755Outbox(outboxAddr);

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

        return (destinationChain, receiver, calls, attributes);
    }

    // Including to block from coverage report
    function test() external {}
}
