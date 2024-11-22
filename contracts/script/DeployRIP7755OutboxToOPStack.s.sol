// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script} from "forge-std/Script.sol";

import {RIP7755OutboxToOPStack} from "../src/outboxes/RIP7755OutboxToOPStack.sol";

contract DeployRIP7755OutboxToOPStack is Script {
    function run() external returns (RIP7755OutboxToOPStack) {
        vm.startBroadcast();
        RIP7755OutboxToOPStack outbox = new RIP7755OutboxToOPStack();
        vm.stopBroadcast();

        return outbox;
    }
}
