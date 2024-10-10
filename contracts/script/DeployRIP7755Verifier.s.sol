// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script} from "forge-std/Script.sol";

import {RIP7755Verifier} from "../src/RIP7755Verifier.sol";

contract DeployRIP7755Verifier is Script {
    function run() external returns (RIP7755Verifier) {
        vm.startBroadcast();
        RIP7755Verifier verifier = new RIP7755Verifier();
        vm.stopBroadcast();

        return verifier;
    }
}
