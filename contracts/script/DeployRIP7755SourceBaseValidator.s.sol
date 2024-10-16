// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script} from "forge-std/Script.sol";

import {RIP7755SourceOPStackValidator} from "../src/source/RIP7755SourceOPStackValidator.sol";

contract DeployRIP7755SourceBaseValidator is Script {
    function run() external returns (RIP7755SourceOPStackValidator) {
        vm.startBroadcast();
        RIP7755SourceOPStackValidator source = new RIP7755SourceOPStackValidator();
        vm.stopBroadcast();

        return source;
    }
}
