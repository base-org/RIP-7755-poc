// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script} from "forge-std/Script.sol";

import {CAIP10} from "../../src/libraries/CAIP10.sol";
import {GlobalTypes} from "../../src/libraries/GlobalTypes.sol";
import {ERC7786Base} from "../../src/ERC7786Base.sol";
import {RIP7755Outbox} from "../../src/RIP7755Outbox.sol";
import {Call} from "../../src/RIP7755Structs.sol";
import {HelperConfig} from "../HelperConfig.s.sol";

contract SubmitRequest is Script, ERC7786Base {
    using GlobalTypes for address;
    using CAIP10 for address;

    HelperConfig public helperConfig;

    bytes32 private constant _NATIVE_ASSET = 0x000000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee;

    constructor() {
        helperConfig = new HelperConfig();
    }

    function run() external {
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig(block.chainid);

        address outboxAddr = config.hashiOutbox;
        uint256 destinationChainId = helperConfig.BASE_SEPOLIA_CHAIN_ID();

        RIP7755Outbox outbox = RIP7755Outbox(outboxAddr);

        (string memory receiver, bytes memory payload, bytes[] memory attributes) = _initMessage(destinationChainId);

        vm.startBroadcast(config.deployerKey);
        outbox.sendMessage("", receiver, payload, attributes);
        vm.stopBroadcast();
    }

    function _initMessage(uint256 destinationChainId)
        private
        view
        returns (string memory, bytes memory, bytes[] memory)
    {
        HelperConfig.NetworkConfig memory dstConfig = helperConfig.getConfig(destinationChainId);

        Call[] memory calls = new Call[](1);
        calls[0] =
            Call({to: 0x8C1a617BdB47342F9C17Ac8750E0b070c372C721.addressToBytes32(), data: "", value: 0.0001 ether});

        string memory receiver = dstConfig.inbox.local();
        bytes memory payload = abi.encode(calls);
        bytes[] memory attributes = new bytes[](3);

        attributes[0] = abi.encodeWithSelector(_REWARD_ATTRIBUTE_SELECTOR, _NATIVE_ASSET, 0.0002 ether);
        attributes[1] = abi.encodeWithSelector(_DELAY_ATTRIBUTE_SELECTOR, 1 weeks, block.timestamp + 2 weeks);
        attributes[2] = abi.encodeWithSelector(_L2_ORACLE_ATTRIBUTE_SELECTOR, dstConfig.l2Oracle);

        return (receiver, payload, attributes);
    }
}
