// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script} from "forge-std/Script.sol";

import {OPStackProver} from "../src/provers/OPStackProver.sol";

contract DeployOPStackProver is Script {
    function run() external returns (OPStackProver) {
        vm.startBroadcast();
        OPStackProver outbox = new OPStackProver();
        vm.stopBroadcast();

        return outbox;
    }
}
