// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script} from "forge-std/Script.sol";

import {RIP7755Inbox} from "../src/RIP7755Inbox.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployRIP7755Inbox is Script {
    HelperConfig public helperConfig;

    constructor() {
        helperConfig = new HelperConfig();
    }

    function run() external returns (RIP7755Inbox) {
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig(block.chainid);

        vm.startBroadcast();
        RIP7755Inbox inbox = new RIP7755Inbox(config.entryPoint);
        vm.stopBroadcast();

        return inbox;
    }
}
