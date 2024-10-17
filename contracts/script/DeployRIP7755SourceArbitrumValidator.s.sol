// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script} from "forge-std/Script.sol";

import {RIP7755OutboxArbitrumValidator} from "../src/source/RIP7755SourceArbitrumValidator.sol";

contract DeployRIP7755OutboxArbitrumValidator is Script {
    function run() external returns (RIP7755OutboxArbitrumValidator) {
        vm.startBroadcast();
        RIP7755OutboxArbitrumValidator outbox = new RIP7755OutboxArbitrumValidator();
        vm.stopBroadcast();

        return outbox;
    }
}
