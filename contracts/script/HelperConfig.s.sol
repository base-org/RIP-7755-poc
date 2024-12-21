// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script} from "forge-std/Script.sol";

contract HelperConfig is Script {
    struct NetworkConfig {
        uint256 chainId;
        address opStackOutbox;
        address arbitrumOutbox;
        address hashiOutbox;
        address inbox;
        address l2Oracle;
        address shoyuBashi;
        uint256 deployerKey;
    }

    uint256 public DEFAULT_ANVIL_PRIVATE_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

    uint256 public constant ARBITRUM_SEPOLIA_CHAIN_ID = 421614;
    uint256 public constant BASE_SEPOLIA_CHAIN_ID = 84532;
    uint256 public constant OPTIMISM_SEPOLIA_CHAIN_ID = 11155420;

    function getConfig(uint256 chainId) public view returns (NetworkConfig memory config) {
        if (chainId == ARBITRUM_SEPOLIA_CHAIN_ID) {
            return getArbitrumSepoliaConfig();
        } else if (chainId == BASE_SEPOLIA_CHAIN_ID) {
            return getBaseSepoliaConfig();
        } else if (chainId == OPTIMISM_SEPOLIA_CHAIN_ID) {
            return getOptimismSepoliaConfig();
        }

        require(false, "Unsupported chain");
    }

    function getArbitrumSepoliaConfig() public view returns (NetworkConfig memory) {
        return NetworkConfig({
            chainId: ARBITRUM_SEPOLIA_CHAIN_ID,
            opStackOutbox: 0x70133C8D5b8fAcd20EAb47D609611009f39ae2D8,
            arbitrumOutbox: address(0),
            hashiOutbox: 0xF648758260bfA7A9dBe1B69f471b23AfFf1cBa6E,
            inbox: 0x5873D69cd7Cd6f1040AA87E6107eB6516E9F5359,
            l2Oracle: 0x042B2E6C5E99d4c521bd49beeD5E99651D9B0Cf4,
            shoyuBashi: 0x5ecAEc6E028da6c29516Fc51aAB740a1B1CF9666,
            deployerKey: vm.envUint("PRIVATE_KEY")
        });
    }

    function getBaseSepoliaConfig() public view returns (NetworkConfig memory) {
        return NetworkConfig({
            chainId: BASE_SEPOLIA_CHAIN_ID,
            opStackOutbox: 0x887f1Bf9F66DFc92901daCcC3d88462b17251B75,
            arbitrumOutbox: 0x3D52b08C3B7Bf624eAD9A79b2e689eA93b80A270,
            hashiOutbox: 0x61B4C289F10f77713C0f1fb38B70741E404Be347,
            inbox: 0x4C1e8c60c3f07AD8A0d08FCD5Cf93f6b73dFeB76,
            l2Oracle: 0x4C8BA32A5DAC2A720bb35CeDB51D6B067D104205,
            shoyuBashi: 0x6602dc9b6bd964C2a11BBdA9B2275308D1Bbc14f,
            deployerKey: vm.envUint("PRIVATE_KEY")
        });
    }

    function getOptimismSepoliaConfig() public view returns (NetworkConfig memory) {
        return NetworkConfig({
            chainId: OPTIMISM_SEPOLIA_CHAIN_ID,
            opStackOutbox: 0xb0524e2D930A46b4B7Eea9fb1E586d00823f66D9,
            arbitrumOutbox: 0x558D42DFD77B6E0aD643F63C23aaba426359cd75,
            hashiOutbox: 0x3365567988f788F7e878377CF211CC98A3505E15,
            inbox: 0xcDdCD048d3AbdE4c917391f65fE296B64841619C,
            l2Oracle: 0x218CD9489199F321E1177b56385d333c5B598629,
            shoyuBashi: 0x7237bb8d1d38DF8b473b5A38eD90088AF162ad8e,
            deployerKey: vm.envUint("PRIVATE_KEY")
        });
    }
}
