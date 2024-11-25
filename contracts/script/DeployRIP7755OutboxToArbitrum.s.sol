// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script} from "forge-std/Script.sol";

import {RIP7755OutboxToArbitrum} from "../src/outboxes/RIP7755OutboxToArbitrum.sol";

contract DeployRIP7755OutboxToArbitrum is Script {
    function run() external returns (RIP7755OutboxToArbitrum) {
        vm.startBroadcast();
        RIP7755OutboxToArbitrum outbox = new RIP7755OutboxToArbitrum();
        vm.stopBroadcast();

        return outbox;
    }
}
