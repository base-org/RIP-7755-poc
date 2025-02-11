// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {Strings} from "openzeppelin-contracts/contracts/utils/Strings.sol";

import {RRC7755OutboxToArbitrum} from "../src/outboxes/RRC7755OutboxToArbitrum.sol";
import {RRC7755OutboxToOPStack} from "../src/outboxes/RRC7755OutboxToOPStack.sol";
import {RRC7755OutboxToHashi} from "../src/outboxes/RRC7755OutboxToHashi.sol";
import {RRC7755Inbox} from "../src/RRC7755Inbox.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract Deploy is Script {
    struct Cfg {
        string chainName;
        string rpcUrl;
    }

    address ENTRY_POINT = 0x0000000071727De22E5E9d8BAf0edAc6f37da032;

    HelperConfig public helperConfig;
    Cfg[3] chains;

    constructor() {
        helperConfig = new HelperConfig();

        chains[0] = Cfg({chainName: "arbitrumSepolia", rpcUrl: vm.envString("ARBITRUM_SEPOLIA_RPC")});
        chains[1] = Cfg({chainName: "baseSepolia", rpcUrl: vm.envString("BASE_SEPOLIA_RPC")});
        chains[2] = Cfg({chainName: "optimismSepolia", rpcUrl: vm.envString("OPTIMISM_SEPOLIA_RPC")});
    }

    function run() external {
        string memory out = "{";

        for (uint256 i; i < chains.length; i++) {
            vm.createSelectFork(chains[i].rpcUrl);

            out = string.concat(out, "\"", chains[i].chainName, "\": {");

            vm.startBroadcast();

            out = _record(out, address(new RRC7755Inbox(ENTRY_POINT)), "RRC7755Inbox");
            if (block.chainid != 421614) {
                out = _record(out, address(new RRC7755OutboxToArbitrum()), "RRC7755OutboxToArbitrum");
            }
            out = _record(out, address(new RRC7755OutboxToOPStack()), "RRC7755OutboxToOPStack");
            out = _record(out, address(new RRC7755OutboxToHashi()), "RRC7755OutboxToHashi");

            vm.stopBroadcast();

            out = string.concat(out, "},");
        }

        out = string.concat(out, "}");

        vm.writeFile("addresses.json", out);
    }

    function _record(string memory out, address contractAddr, string memory key) private pure returns (string memory) {
        return string.concat(out, "\"", key, "\": \"", Strings.toHexString(contractAddr), "\",");
    }

    // Including to block from coverage report
    function test() external {}
}
