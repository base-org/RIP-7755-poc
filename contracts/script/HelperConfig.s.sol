// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script} from "forge-std/Script.sol";
import {stdJson} from "forge-std/StdJson.sol";

import {EntryPoint} from "account-abstraction/core/EntryPoint.sol";

import {MockAccount} from "../test/mocks/MockAccount.sol";

contract HelperConfig is Script {
    using stdJson for string;

    struct NetworkConfig {
        uint256 chainId;
        address opStackOutbox;
        address arbitrumOutbox;
        address hashiOutbox;
        address inbox;
        address l2Oracle;
        address shoyuBashi;
        address smartAccount;
        string rpcUrl;
    }

    uint256 public constant ARBITRUM_SEPOLIA_CHAIN_ID = 421614;
    uint256 public constant BASE_SEPOLIA_CHAIN_ID = 84532;
    uint256 public constant OPTIMISM_SEPOLIA_CHAIN_ID = 11155420;
    uint256 public constant LOCAL_CHAIN_ID = 31337;

    string addresses;

    constructor() {
        string memory rootPath = vm.projectRoot();
        string memory path = string.concat(rootPath, "/addresses.json");
        addresses = vm.readFile(path);
    }

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
            opStackOutbox: addresses.readAddress(".arbitrumSepolia.RRC7755OutboxToOPStack"),
            arbitrumOutbox: address(0),
            hashiOutbox: addresses.readAddress(".arbitrumSepolia.RRC7755OutboxToHashi"),
            inbox: addresses.readAddress(".arbitrumSepolia.RRC7755Inbox"),
            l2Oracle: 0x042B2E6C5E99d4c521bd49beeD5E99651D9B0Cf4,
            shoyuBashi: 0xce8b068D4F7F2eb3bDAFa72eC3C4feE78CF9Ccf7,
            smartAccount: 0x2c4d5B2d8B7ba9e15F09Da8fD455E312bF774Eeb,
            rpcUrl: vm.envString("ARBITRUM_SEPOLIA_RPC")
        });
    }

    function getBaseSepoliaConfig() public view returns (NetworkConfig memory) {
        return NetworkConfig({
            chainId: BASE_SEPOLIA_CHAIN_ID,
            opStackOutbox: addresses.readAddress(".baseSepolia.RRC7755OutboxToOPStack"),
            arbitrumOutbox: addresses.readAddress(".baseSepolia.RRC7755OutboxToArbitrum"),
            hashiOutbox: addresses.readAddress(".baseSepolia.RRC7755OutboxToHashi"),
            inbox: addresses.readAddress(".baseSepolia.RRC7755Inbox"),
            l2Oracle: 0x4C8BA32A5DAC2A720bb35CeDB51D6B067D104205,
            shoyuBashi: 0x6602dc9b6bd964C2a11BBdA9B2275308D1Bbc14f,
            smartAccount: 0x2c4d5B2d8B7ba9e15F09Da8fD455E312bF774Eeb,
            rpcUrl: vm.envString("BASE_SEPOLIA_RPC")
        });
    }

    function getOptimismSepoliaConfig() public view returns (NetworkConfig memory) {
        return NetworkConfig({
            chainId: OPTIMISM_SEPOLIA_CHAIN_ID,
            opStackOutbox: addresses.readAddress(".optimismSepolia.RRC7755OutboxToOPStack"),
            arbitrumOutbox: addresses.readAddress(".optimismSepolia.RRC7755OutboxToArbitrum"),
            hashiOutbox: addresses.readAddress(".optimismSepolia.RRC7755OutboxToHashi"),
            inbox: addresses.readAddress(".optimismSepolia.RRC7755Inbox"),
            l2Oracle: 0x218CD9489199F321E1177b56385d333c5B598629,
            shoyuBashi: 0x7237bb8d1d38DF8b473b5A38eD90088AF162ad8e,
            smartAccount: 0x2c4d5B2d8B7ba9e15F09Da8fD455E312bF774Eeb,
            rpcUrl: vm.envString("OPTIMISM_SEPOLIA_RPC")
        });
    }

    function getLocalConfig() public returns (NetworkConfig memory) {
        MockAccount smartAccount = new MockAccount();

        return NetworkConfig({
            chainId: LOCAL_CHAIN_ID,
            opStackOutbox: address(0),
            arbitrumOutbox: address(0),
            hashiOutbox: address(0),
            inbox: address(0),
            l2Oracle: address(0),
            shoyuBashi: address(0),
            smartAccount: address(smartAccount),
            rpcUrl: ""
        });
    }

    // Including to block from coverage report
    function test() external {}
}
