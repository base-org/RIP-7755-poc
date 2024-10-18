// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script} from "forge-std/Script.sol";

import {RIP7755Inbox} from "../src/RIP7755Inbox.sol";

contract DeployRIP7755Inbox is Script {
    function run() external returns (RIP7755Inbox) {
        vm.startBroadcast();
        RIP7755Inbox inbox = new RIP7755Inbox();
        vm.stopBroadcast();

        return inbox;
    }
}
