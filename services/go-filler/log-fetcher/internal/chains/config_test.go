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
		name      string
		chainID   int64
		rpcConfig *config.RPCs
		expected  *ChainConfig
	}{
		{
			name:    "Arbitrum Sepolia",
			chainID: 421614,
			rpcConfig: &config.RPCs{
				ArbitrumSepolia: "https://arb-sepolia.example.com",
			},
			expected: &ChainConfig{
				ChainId: big.NewInt(421614),
				ProverContracts: map[string]common.Address{
					config.OPStackProver.String(): common.HexToAddress("0x062fBdCfd17A0346D2A9d89FE233bbAdBd1DC14C"),
				},
				RpcUrl:             "https://arb-sepolia.example.com",
				L2Oracle:           common.HexToAddress("0xd80810638dbDF9081b72C1B33c65375e807281C8"),
				L2OracleStorageKey: encodeBytes("0000000000000000000000000000000000000000000000000000000000000076"),
				Contracts: &Contracts{
					Inbox:  common.HexToAddress("0xeE962eD1671F655a806cB22623eEA8A7cCc233bC"),
					Outbox: common.HexToAddress("0xBCd5762cF9B07EF5597014c350CE2efB2b0DB2D2"),
				},
				TargetProver: config.ArbitrumProver,
			},
		},
		{
			name:    "Base Sepolia",
			chainID: 84532,
			rpcConfig: &config.RPCs{
				BaseSepolia: "https://base-sepolia.example.com",
			},
			expected: &ChainConfig{
				ChainId: big.NewInt(84532),
				ProverContracts: map[string]common.Address{
					config.ArbitrumProver.String(): common.HexToAddress("0x49E2cDC9e81825B6C718ae8244fe0D5b062F4874"),
					config.OPStackProver.String():  common.HexToAddress("0x562879614C9Db8Da9379be1D5B52BAEcDD456d78"),
				},
				RpcUrl:             "https://base-sepolia.example.com",
				L2Oracle:           common.HexToAddress("0x4C8BA32A5DAC2A720bb35CeDB51D6B067D104205"),
				L2OracleStorageKey: encodeBytes("a6eef7e35abe7026729641147f7915573c7e97b47efa546f5f6e3230263bcb49"),
				Contracts: &Contracts{
					Inbox:  common.HexToAddress("0xB482b292878FDe64691d028A2237B34e91c7c7ea"),
					Outbox: common.HexToAddress("0xD7a5A114A07cC4B5ebd9C5e1cD1136a99fFA3d68"),
				},
				TargetProver: config.OPStackProver,
			},
		},
		{
			name:    "Optimism Sepolia",
			chainID: 11155420,
			rpcConfig: &config.RPCs{
				OptimismSepolia: "https://opt-sepolia.example.com",
			},
			expected: &ChainConfig{
				ChainId:            big.NewInt(11155420),
				ProverContracts:    map[string]common.Address{},
				RpcUrl:             "https://opt-sepolia.example.com",
				L2Oracle:           common.HexToAddress("0x218CD9489199F321E1177b56385d333c5B598629"),
				L2OracleStorageKey: encodeBytes("a6eef7e35abe7026729641147f7915573c7e97b47efa546f5f6e3230263bcb49"),
				Contracts: &Contracts{
					L2MessagePasser: common.HexToAddress("0x4200000000000000000000000000000000000016"),
					Inbox:           common.HexToAddress("0x49E2cDC9e81825B6C718ae8244fe0D5b062F4874"),
				},
				TargetProver: config.OPStackProver,
			},
		},
		{
			name:    "Sepolia",
			chainID: 11155111,
			rpcConfig: &config.RPCs{
				Sepolia: "https://sepolia.example.com",
			},
			expected: &ChainConfig{
				ChainId:         big.NewInt(11155111),
				ProverContracts: map[string]common.Address{},
				RpcUrl:          "https://sepolia.example.com",
				Contracts: &Contracts{
					AnchorStateRegistry: common.HexToAddress("0x218CD9489199F321E1177b56385d333c5B598629"),
					ArbRollup:           common.HexToAddress("0xd80810638dbDF9081b72C1B33c65375e807281C8"),
				},
				TargetProver: config.NilProver,
			},
		},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			result, err := GetChainConfig(big.NewInt(tc.chainID), tc.rpcConfig)
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
	result, err := GetChainConfig(unknownChainID, &config.RPCs{})
	if err == nil {
		t.Errorf("GetChainConfig(%d) = %+v, want error", unknownChainID, result)
	}
}

func TestEncodeBytes(t *testing.T) {
	testCases := []struct {
		name     string
		input    string
		expected [32]byte
	}{
		{
			name:     "Empty string",
			input:    "",
			expected: [32]byte{},
		},
		{
			name:  "Short string",
			input: "0102030405",
			expected: [32]byte{
				0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
				0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 2, 3, 4, 5,
			},
		},
		{
			name:  "Full 32-byte string",
			input: "0102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f20",
			expected: [32]byte{
				1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16,
				17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32,
			},
		},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			result := encodeBytes(tc.input)
			if !reflect.DeepEqual(result, tc.expected) {
				t.Errorf("encodeBytes(%s) = %v, want %v", tc.input, result, tc.expected)
			}
		})
	}
}
