// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script} from "forge-std/Script.sol";

import {RIP7755OutboxToHashi} from "../../src/outboxes/RIP7755OutboxToHashi.sol";
import {RIP7755Inbox} from "../../src/RIP7755Inbox.sol";

contract DeployArbitrum is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);
        new RIP7755Inbox();
        new RIP7755OutboxToHashi();
        vm.stopBroadcast();
    }
}
