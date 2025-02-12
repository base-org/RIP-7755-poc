// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {RRC7755Outbox} from "../../src/RRC7755Outbox.sol";
import {HelperConfig} from "../HelperConfig.s.sol";
import {UserOpBase} from "./UserOpBase.s.sol";

contract BaseToOptimism is UserOpBase {
    function run() external {
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig(block.chainid);

        address outboxAddr = config.opStackOutbox;
        uint256 destinationChainId = helperConfig.OPTIMISM_SEPOLIA_CHAIN_ID();
        uint256 duration = 1 weeks;

        RRC7755Outbox outbox = RRC7755Outbox(outboxAddr);

        uint256 nonce = outbox.getNonce(_REQUESTER);

        (bytes32 destinationChain, bytes32 receiver, bytes memory payload, bytes[] memory attributes) =
            _initMessage(destinationChainId, duration, nonce + 1);

        vm.createSelectFork(config.rpcUrl);

        vm.startBroadcast();
        outbox.sendMessage{value: 0.0002 ether}(destinationChain, receiver, payload, attributes);
        vm.stopBroadcast();
    }

    // Including to block from coverage report
    function test() external {}
}
