package chains

import (
	"math/big"
	"reflect"
	"testing"

	"github.com/base-org/RIP-7755-poc/services/go-filler/log-fetcher/internal/config"
	"github.com/ethereum/go-ethereum/common"
)

func TestGetChainConfig(t *testing.T) {
	testCases := []struct {
		name     string
		chainID  *big.Int
		expected *ChainConfig
		networks Networks
	}{
		{
			name:    "Arbitrum Sepolia",
			chainID: big.NewInt(421614),
			expected: &ChainConfig{
				ChainId: big.NewInt(421614),
				ProverContracts: map[string]common.Address{
					config.OPStackProver.String(): common.HexToAddress("0x062fBdCfd17A0346D2A9d89FE233bbAdBd1DC14C"),
				},
				RpcUrl:             "https://arb-sepolia.example.com",
				L2Oracle:           common.HexToAddress("0xd80810638dbDF9081b72C1B33c65375e807281C8"),
				L2OracleStorageKey: "0x0000000000000000000000000000000000000000000000000000000000000076",
				Contracts: &Contracts{
					Inbox:  common.HexToAddress("0xeE962eD1671F655a806cB22623eEA8A7cCc233bC"),
					Outbox: common.HexToAddress("0xBCd5762cF9B07EF5597014c350CE2efB2b0DB2D2"),
				},
				TargetProver: config.ArbitrumProver,
			},
			networks: Networks{
				"421614": {
					ChainId: big.NewInt(421614),
					ProverContracts: map[string]common.Address{
						config.OPStackProver.String(): common.HexToAddress("0x062fBdCfd17A0346D2A9d89FE233bbAdBd1DC14C"),
					},
					RpcUrl:             "https://arb-sepolia.example.com",
					L2Oracle:           common.HexToAddress("0xd80810638dbDF9081b72C1B33c65375e807281C8"),
					L2OracleStorageKey: "0x0000000000000000000000000000000000000000000000000000000000000076",
					Contracts: &Contracts{
						Inbox:  common.HexToAddress("0xeE962eD1671F655a806cB22623eEA8A7cCc233bC"),
						Outbox: common.HexToAddress("0xBCd5762cF9B07EF5597014c350CE2efB2b0DB2D2"),
					},
					TargetProver: config.ArbitrumProver,
				},
			},
		},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			result, err := tc.networks.GetChainConfig(tc.chainID)
			if err != nil {
				t.Errorf("GetChainConfig(%d) returned error: %v", tc.chainID, err)
			}

			if !reflect.DeepEqual(result, tc.expected) {
				t.Errorf("GetChainConfig(%d) = %+v, want %+v", tc.chainID, result, tc.expected)
			}
		})
	}
}

func TestGetChainConfig_UnknownChain(t *testing.T) {
	unknownChainID := big.NewInt(999999)
	result, err := (&Networks{}).GetChainConfig(unknownChainID)
	if err == nil {
		t.Errorf("GetChainConfig(%d) = %+v, want error", unknownChainID, result)
	}
}
