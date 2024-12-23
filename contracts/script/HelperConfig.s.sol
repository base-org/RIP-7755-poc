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
            opStackOutbox: 0x47b5B7908C5713741275F02573b1E1c923De53b6,
            arbitrumOutbox: address(0),
            hashiOutbox: 0xEea9a1118F80C7318c87ecC9E74638eE4adB4a6b,
            inbox: 0x3925cA932720B63ccD2C359DF27fD4146b123628,
            l2Oracle: 0x042B2E6C5E99d4c521bd49beeD5E99651D9B0Cf4,
            shoyuBashi: 0x5ecAEc6E028da6c29516Fc51aAB740a1B1CF9666,
            deployerKey: vm.envUint("PRIVATE_KEY")
        });
    }

    function getBaseSepoliaConfig() public view returns (NetworkConfig memory) {
        return NetworkConfig({
            chainId: BASE_SEPOLIA_CHAIN_ID,
            opStackOutbox: 0x778BBC9031303111863556A839f942fa57958dAB,
            arbitrumOutbox: 0xAD1F7De075f304821838d5b7D53B6Af3787acB84,
            hashiOutbox: 0x421194292DC69C440528d3865Ae6A2B22F683Cb6,
            inbox: 0x0D595D4d3dC06548D536e74528C5B8ecc2171B31,
            l2Oracle: 0x4C8BA32A5DAC2A720bb35CeDB51D6B067D104205,
            shoyuBashi: 0x6602dc9b6bd964C2a11BBdA9B2275308D1Bbc14f,
            deployerKey: vm.envUint("PRIVATE_KEY")
        });
    }

    function getOptimismSepoliaConfig() public view returns (NetworkConfig memory) {
        return NetworkConfig({
            chainId: OPTIMISM_SEPOLIA_CHAIN_ID,
            opStackOutbox: 0x10971bB1913D3Fa79B0503aF4568CA11f237E919,
            arbitrumOutbox: 0xCe255d8676A34575bd580D1520f0e2968Ea45Ec3,
            hashiOutbox: 0xcCB16Bf719ac9A0D125d7491Dfa897E9053Ca415,
            inbox: 0x27B9e81C31eab9fdB8Ed1280680b23299FBa4cd8,
            l2Oracle: 0x218CD9489199F321E1177b56385d333c5B598629,
            shoyuBashi: 0x7237bb8d1d38DF8b473b5A38eD90088AF162ad8e,
            deployerKey: vm.envUint("PRIVATE_KEY")
        });
    }
}
