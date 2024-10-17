// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script} from "forge-std/Script.sol";

import {RIP7755OutboxOPStackValidator} from "../src/source/RIP7755SourceOPStackValidator.sol";

contract DeployRIP7755OutboxBaseValidator is Script {
    function run() external returns (RIP7755OutboxOPStackValidator) {
        vm.startBroadcast();
        RIP7755OutboxOPStackValidator outbox = new RIP7755OutboxOPStackValidator();
        vm.stopBroadcast();

        return outbox;
    }
}
