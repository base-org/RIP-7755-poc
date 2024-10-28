// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script} from "forge-std/Script.sol";

import {HashiProver} from "../src/provers/HashiProver.sol";

contract DeployHashiProver is Script {
    function run() external returns (HashiProver) {
        vm.startBroadcast();
        HashiProver outbox = new HashiProver();
        vm.stopBroadcast();

        return outbox;
    }
}
