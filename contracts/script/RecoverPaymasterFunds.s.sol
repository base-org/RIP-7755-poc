// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {console} from "forge-std/console.sol";

import {HelperConfig} from "./HelperConfig.s.sol";
import {MultiChain} from "./MultiChain.sol";
import {Paymaster} from "../src/Paymaster.sol";

contract RecoverPaymasterFunds is MultiChain {
    address public constant FULFILLER = 0x8C1a617BdB47342F9C17Ac8750E0b070c372C721;
    address private constant _ETH_ADDRESS = address(0);

    function run() public {
        HelperConfig helperConfig = new HelperConfig();

        for (uint256 i; i < chains.length; i++) {
            vm.createSelectFork(chains[i].rpcUrl);

            HelperConfig.NetworkConfig memory cfg = helperConfig.getConfig(block.chainid);

            Paymaster paymaster = Paymaster(payable(cfg.inbox));

            uint256 entryPointBalance = paymaster.getGasBalance(FULFILLER);
            uint256 magicSpendBalance = paymaster.getMagicSpendBalance(FULFILLER, _ETH_ADDRESS);

            vm.startBroadcast();
            if (entryPointBalance > 0) {
                console.log("Withdrawing entry point balance: ", entryPointBalance);
                paymaster.entryPointWithdrawTo(payable(FULFILLER), entryPointBalance);
            }

            if (magicSpendBalance > 0) {
                console.log("Withdrawing magic spend balance: ", magicSpendBalance);
                paymaster.withdrawTo(_ETH_ADDRESS, FULFILLER, magicSpendBalance);
            }
            vm.stopBroadcast();
        }
    }

    // Including to block from coverage report
    function test() external {}
}
