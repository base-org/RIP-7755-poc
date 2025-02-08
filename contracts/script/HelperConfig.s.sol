// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script} from "forge-std/Script.sol";

import {EntryPoint} from "account-abstraction/core/EntryPoint.sol";

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
        address entryPoint;
    }

    uint256 public DEFAULT_ANVIL_PRIVATE_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

    uint256 public constant ARBITRUM_SEPOLIA_CHAIN_ID = 421614;
    uint256 public constant BASE_SEPOLIA_CHAIN_ID = 84532;
    uint256 public constant OPTIMISM_SEPOLIA_CHAIN_ID = 11155420;
    uint256 public constant LOCAL_CHAIN_ID = 31337;

    function getConfig(uint256 chainId) public returns (NetworkConfig memory config) {
        if (chainId == ARBITRUM_SEPOLIA_CHAIN_ID) {
            return getArbitrumSepoliaConfig();
        } else if (chainId == BASE_SEPOLIA_CHAIN_ID) {
            return getBaseSepoliaConfig();
        } else if (chainId == OPTIMISM_SEPOLIA_CHAIN_ID) {
            return getOptimismSepoliaConfig();
        } else if (chainId == LOCAL_CHAIN_ID) {
            return getLocalConfig();
        }

        require(false, "Unsupported chain");
    }

    function getArbitrumSepoliaConfig() public view returns (NetworkConfig memory) {
        return NetworkConfig({
            chainId: ARBITRUM_SEPOLIA_CHAIN_ID,
            opStackOutbox: address(0),
            arbitrumOutbox: address(0),
            hashiOutbox: 0x09F9E99d379A9963Fe13814b31B90ba81bf9a74f,
            inbox: 0xAF8e568F4E3105e1D8818B26dCA57CD4bd753695,
            l2Oracle: 0x042B2E6C5E99d4c521bd49beeD5E99651D9B0Cf4,
            shoyuBashi: 0xce8b068D4F7F2eb3bDAFa72eC3C4feE78CF9Ccf7,
            deployerKey: vm.envUint("PRIVATE_KEY"),
            entryPoint: 0x0000000071727De22E5E9d8BAf0edAc6f37da032
        });
    }

    function getBaseSepoliaConfig() public view returns (NetworkConfig memory) {
        return NetworkConfig({
            chainId: BASE_SEPOLIA_CHAIN_ID,
            opStackOutbox: 0x99FCF11772af0a9Cc411af3CB4311A387Dd55b15,
            arbitrumOutbox: 0xBb174bdaF21d8Ee40763fD5a859B0164365C64FF,
            hashiOutbox: 0xE4401EB53AE90a5335a51fe1828d7BeCf7a63508,
            inbox: 0x8e993853C303288f4fcd138E180E31a3c798E4F9,
            l2Oracle: 0x4C8BA32A5DAC2A720bb35CeDB51D6B067D104205,
            shoyuBashi: 0x6602dc9b6bd964C2a11BBdA9B2275308D1Bbc14f,
            deployerKey: vm.envUint("PRIVATE_KEY"),
            entryPoint: 0x0000000071727De22E5E9d8BAf0edAc6f37da032
        });
    }

    function getOptimismSepoliaConfig() public view returns (NetworkConfig memory) {
        return NetworkConfig({
            chainId: OPTIMISM_SEPOLIA_CHAIN_ID,
            opStackOutbox: 0x4b43589e343365F922C257ff48975c885A54e8D0,
            arbitrumOutbox: 0xe38f582b29144C8614B5bD90A95B1E62F4D672F0,
            hashiOutbox: 0x0D595D4d3dC06548D536e74528C5B8ecc2171B31,
            inbox: 0x9435B271fB6b525B87171F92379A5c85fEF4d4cB,
            l2Oracle: 0x218CD9489199F321E1177b56385d333c5B598629,
            shoyuBashi: 0x7237bb8d1d38DF8b473b5A38eD90088AF162ad8e,
            deployerKey: vm.envUint("PRIVATE_KEY"),
            entryPoint: 0x0000000071727De22E5E9d8BAf0edAc6f37da032
        });
    }

    function getLocalConfig() public returns (NetworkConfig memory) {
        EntryPoint entryPoint = new EntryPoint();

        return NetworkConfig({
            chainId: LOCAL_CHAIN_ID,
            opStackOutbox: address(0),
            arbitrumOutbox: address(0),
            hashiOutbox: address(0),
            inbox: address(0),
            l2Oracle: address(0),
            shoyuBashi: address(0),
            deployerKey: 0,
            entryPoint: address(entryPoint)
        });
    }

    // Including to block from coverage report
    function test() external {}
}
