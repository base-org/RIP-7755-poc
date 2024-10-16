// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script} from "forge-std/Script.sol";

import {RIP7755SourceArbitrumValidator} from "../src/source/RIP7755SourceArbitrumValidator.sol";

contract DeployRIP7755SourceArbitrumValidator is Script {
    function run() external returns (RIP7755SourceArbitrumValidator) {
        vm.startBroadcast();
        RIP7755SourceArbitrumValidator source = new RIP7755SourceArbitrumValidator();
        vm.stopBroadcast();

        return source;
    }
}
