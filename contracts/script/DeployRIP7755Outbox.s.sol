// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script} from "forge-std/Script.sol";

import {RIP7755Outbox} from "../src/RIP7755Outbox.sol";

contract DeployRIP7755Outbox is Script {
    function run() external returns (RIP7755Outbox) {
        vm.startBroadcast();
        RIP7755Outbox outbox = new RIP7755Outbox();
        vm.stopBroadcast();

        return outbox;
    }
}
