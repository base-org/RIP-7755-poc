// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script} from "forge-std/Script.sol";

import {OPStackProver} from "../../src/provers/OPStackProver.sol";
import {RIP7755Inbox} from "../../src/RIP7755Inbox.sol";
import {RIP7755Outbox} from "../../src/RIP7755Outbox.sol";

contract DeployArbitrum is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);
        new OPStackProver();
        new RIP7755Inbox();
        new RIP7755Outbox();
        vm.stopBroadcast();
    }
}
