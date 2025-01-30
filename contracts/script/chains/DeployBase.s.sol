// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script} from "forge-std/Script.sol";

import {RIP7755OutboxToArbitrum} from "../../src/outboxes/RIP7755OutboxToArbitrum.sol";
import {RIP7755OutboxToOPStack} from "../../src/outboxes/RIP7755OutboxToOPStack.sol";
import {RIP7755OutboxToHashi} from "../../src/outboxes/RIP7755OutboxToHashi.sol";
import {RIP7755Inbox} from "../../src/RIP7755Inbox.sol";
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
        new RIP7755Inbox(config.entryPoint);
        new RIP7755OutboxToArbitrum();
        new RIP7755OutboxToOPStack();
        new RIP7755OutboxToHashi();
        vm.stopBroadcast();
    }
}
