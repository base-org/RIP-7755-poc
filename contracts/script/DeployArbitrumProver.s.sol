// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script} from "forge-std/Script.sol";

import {ArbitrumProver} from "../src/provers/ArbitrumProver.sol";

contract DeployArbitrumProver is Script {
    function run() external returns (ArbitrumProver) {
        vm.startBroadcast();
        ArbitrumProver outbox = new ArbitrumProver();
        vm.stopBroadcast();

        return outbox;
    }
}
