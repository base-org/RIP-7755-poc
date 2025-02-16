// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script} from "forge-std/Script.sol";

abstract contract MultiChain is Script {
    struct Cfg {
        string chainName;
        string rpcUrl;
    }

    address ENTRY_POINT = 0x0000000071727De22E5E9d8BAf0edAc6f37da032;
    Cfg[3] chains;

    constructor() {
        chains[0] = Cfg({chainName: "arbitrumSepolia", rpcUrl: vm.envString("ARBITRUM_SEPOLIA_RPC")});
        chains[1] = Cfg({chainName: "baseSepolia", rpcUrl: vm.envString("BASE_SEPOLIA_RPC")});
        chains[2] = Cfg({chainName: "optimismSepolia", rpcUrl: vm.envString("OPTIMISM_SEPOLIA_RPC")});
    }

    // Including to block from coverage report
    function test_multi() external {}
}
