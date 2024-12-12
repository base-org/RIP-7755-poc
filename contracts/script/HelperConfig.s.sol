// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script} from "forge-std/Script.sol";

contract HelperConfig is Script {
    struct NetworkConfig {
        uint256 chainId;
        address opStackOutbox;
        address arbitrumOutbox;
        address inbox;
        address l2Oracle;
        uint256 deployerKey;
    }

    NetworkConfig public networkConfig;

    uint256 public DEFAULT_ANVIL_PRIVATE_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

    constructor() {
        if (block.chainid == 421614) {
            networkConfig = getArbitrumSepoliaConfig();
        } else if (block.chainid == 84532) {
            networkConfig = getBaseSepoliaConfig();
        } else if (block.chainid == 11155420) {
            networkConfig = getOptimismSepoliaConfig();
        }
    }

    function getConfig(uint256 chainId) public view returns (NetworkConfig memory config) {
        if (chainId == 421614) {
            return getArbitrumSepoliaConfig();
        } else if (chainId == 84532) {
            return getBaseSepoliaConfig();
        } else if (chainId == 11155420) {
            return getOptimismSepoliaConfig();
        }

        require(false, "Unsupported chain");
    }

    function getArbitrumSepoliaConfig() public view returns (NetworkConfig memory) {
        return NetworkConfig({
            chainId: 421614,
            opStackOutbox: 0x3eD4f0892020a9C57586c33554032be00fE379E4,
            arbitrumOutbox: address(0),
            inbox: 0xCdadDE9005974Fbd3385184d1C1C34ef455Cb2Be,
            l2Oracle: 0xd80810638dbDF9081b72C1B33c65375e807281C8,
            deployerKey: vm.envUint("PRIVATE_KEY")
        });
    }

    function getBaseSepoliaConfig() public view returns (NetworkConfig memory) {
        return NetworkConfig({
            chainId: 84532,
            opStackOutbox: 0x558D42DFD77B6E0aD643F63C23aaba426359cd75,
            arbitrumOutbox: 0xcDdCD048d3AbdE4c917391f65fE296B64841619C,
            inbox: 0xFce77110df39c54681a0769EB515cCE862d074d9,
            l2Oracle: 0x4C8BA32A5DAC2A720bb35CeDB51D6B067D104205,
            deployerKey: vm.envUint("PRIVATE_KEY")
        });
    }

    function getOptimismSepoliaConfig() public view returns (NetworkConfig memory) {
        return NetworkConfig({
            chainId: 11155420,
            opStackOutbox: 0xB482b292878FDe64691d028A2237B34e91c7c7ea,
            arbitrumOutbox: 0xD7a5A114A07cC4B5ebd9C5e1cD1136a99fFA3d68,
            inbox: 0xaC60fCC226899F14016d14CfCC955598D4cbe10F,
            l2Oracle: 0x218CD9489199F321E1177b56385d333c5B598629,
            deployerKey: vm.envUint("PRIVATE_KEY")
        });
    }
}
