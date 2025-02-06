// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script} from "forge-std/Script.sol";

import {RRC7755OutboxToArbitrum} from "../../src/outboxes/RRC7755OutboxToArbitrum.sol";
import {RRC7755OutboxToOPStack} from "../../src/outboxes/RRC7755OutboxToOPStack.sol";
import {RRC7755OutboxToHashi} from "../../src/outboxes/RRC7755OutboxToHashi.sol";
import {RRC7755Inbox} from "../../src/RRC7755Inbox.sol";
import {HelperConfig} from "../HelperConfig.s.sol";

contract DeployBase is Script {
    HelperConfig public helperConfig;

    constructor() {
        helperConfig = new HelperConfig();
    }

    function run() external {
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig(block.chainid);
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);
        new RRC7755Inbox(config.entryPoint);
        new RRC7755OutboxToArbitrum();
        new RRC7755OutboxToOPStack();
        new RRC7755OutboxToHashi();
        vm.stopBroadcast();
    }

    // Including to block from coverage report
    function test() external {}
}
