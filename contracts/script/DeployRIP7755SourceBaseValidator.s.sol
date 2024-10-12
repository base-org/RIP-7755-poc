// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script} from "forge-std/Script.sol";

import {RIP7755SourceBaseValidator} from "../src/RIP7755SourceBaseValidator.sol";

contract DeployRIP7755SourceBaseValidator is Script {
    function run() external returns (RIP7755SourceBaseValidator) {
        vm.startBroadcast();
        RIP7755SourceBaseValidator source = new RIP7755SourceBaseValidator();
        vm.stopBroadcast();

        return source;
    }
}
