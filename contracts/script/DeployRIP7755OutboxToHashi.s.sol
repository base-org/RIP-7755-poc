// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script} from "forge-std/Script.sol";

import {RIP7755OutboxToHashi} from "../src/outboxes/RIP7755OutboxToHashi.sol";

contract DeployRIP7755OutboxToHashi is Script {
    function run() external returns (RIP7755OutboxToHashi) {
        vm.startBroadcast();
        RIP7755OutboxToHashi outbox = new RIP7755OutboxToHashi();
        vm.stopBroadcast();

        return outbox;
    }
}
