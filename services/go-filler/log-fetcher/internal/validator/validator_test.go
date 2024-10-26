package validator

import (
	"encoding/hex"
	"log"
	"math/big"
	"testing"

	"github.com/base-org/RIP-7755-poc/services/go-filler/log-fetcher/internal/chains"
	"github.com/base-org/RIP-7755-poc/services/go-filler/log-fetcher/internal/config"
	"github.com/base-org/RIP-7755-poc/services/go-filler/log-fetcher/internal/parser"
	"github.com/ethereum/go-ethereum/common"
	"github.com/stretchr/testify/assert"
)

var cfg = &config.Config{
	RPCs: &config.RPCs{
		ArbitrumSepolia: "https://arbitrum-sepolia.llamarpc.com",
	},
}

var srcChain = &chains.ChainConfig{
	ChainId: big.NewInt(42161),
	ProverContracts: map[string]common.Address{
		"OPStackProver": common.HexToAddress("0x1234567890123456789012345678901234567890"),
	},
}

var parsedLog = parser.LogCrossChainCallRequested{
	Request: parser.CrossChainRequest{
		Calls: []parser.Call{
			{
				To:    common.HexToAddress("0x1234567890123456789012345678901234567890"),
				Value: big.NewInt(1000000000000000000),
			},
		},
		DestinationChainId: big.NewInt(84532),
		InboxContract:      common.HexToAddress("0xB482b292878FDe64691d028A2237B34e91c7c7ea"),
		L2Oracle:           common.HexToAddress("0x4C8BA32A5DAC2A720bb35CeDB51D6B067D104205"),
		L2OracleStorageKey: encodeBytes("a6eef7e35abe7026729641147f7915573c7e97b47efa546f5f6e3230263bcb49"),
		ProverContract:     common.HexToAddress("0x1234567890123456789012345678901234567890"),
		RewardAsset:        common.HexToAddress("0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE"),
		RewardAmount:       big.NewInt(2000000000000000000),
	},
}

func TestValidateLog(t *testing.T) {
	validator := NewValidator(cfg, srcChain)

	err := validator.ValidateLog(parsedLog)

	assert.NoError(t, err)
}

func TestValidateLog_UnknownDestinationChain(t *testing.T) {
	validator := NewValidator(cfg, srcChain)

	prevDstChainId := parsedLog.Request.DestinationChainId
	parsedLog.Request.DestinationChainId = big.NewInt(11155112)
	defer func() { parsedLog.Request.DestinationChainId = prevDstChainId }()

	err := validator.ValidateLog(parsedLog)

	assert.Error(t, err)
}

func TestValidateLog_UnknownProverName(t *testing.T) {
	validator := NewValidator(cfg, srcChain)

	prevDstChainId := parsedLog.Request.DestinationChainId
	parsedLog.Request.DestinationChainId = big.NewInt(11155111)
	defer func() { parsedLog.Request.DestinationChainId = prevDstChainId }()

	err := validator.ValidateLog(parsedLog)

	assert.Error(t, err)
}

func TestValidateLog_UnknownProverContract(t *testing.T) {
	validator := NewValidator(cfg, srcChain)

	prevProverContract := parsedLog.Request.ProverContract
	parsedLog.Request.ProverContract = common.HexToAddress("0x1234567890123456789012345678901234567891")
	defer func() { parsedLog.Request.ProverContract = prevProverContract }()

	err := validator.ValidateLog(parsedLog)

	assert.Error(t, err)
}

func TestValidateLog_UnknownInboxContract(t *testing.T) {
	validator := NewValidator(cfg, srcChain)

	prevInboxContract := parsedLog.Request.InboxContract
	parsedLog.Request.InboxContract = common.HexToAddress("0x1234567890123456789012345678901234567891")
	defer func() { parsedLog.Request.InboxContract = prevInboxContract }()

	err := validator.ValidateLog(parsedLog)

	assert.Error(t, err)
}

func TestValidateLog_UnknownL2Oracle(t *testing.T) {
	validator := NewValidator(cfg, srcChain)

	prevL2Oracle := parsedLog.Request.L2Oracle
	parsedLog.Request.L2Oracle = common.HexToAddress("0x1234567890123456789012345678901234567891")
	defer func() { parsedLog.Request.L2Oracle = prevL2Oracle }()

	err := validator.ValidateLog(parsedLog)

	assert.Error(t, err)
}

func TestValidateLog_UnknownL2OracleStorageKey(t *testing.T) {
	validator := NewValidator(cfg, srcChain)

	prevL2OracleStorageKey := parsedLog.Request.L2OracleStorageKey
	parsedLog.Request.L2OracleStorageKey = encodeBytes("1234567890123456789012345678901234567891")
	defer func() { parsedLog.Request.L2OracleStorageKey = prevL2OracleStorageKey }()

	err := validator.ValidateLog(parsedLog)

	assert.Error(t, err)
}

func TestValidateLog_InvalidReward_NotNativeAsset(t *testing.T) {
	validator := NewValidator(cfg, srcChain)

	prevRewardAsset := parsedLog.Request.RewardAsset
	parsedLog.Request.RewardAsset = common.HexToAddress("0x1234567890123456789012345678901234567891")
	defer func() { parsedLog.Request.RewardAsset = prevRewardAsset }()

	err := validator.ValidateLog(parsedLog)

	assert.Error(t, err)
}

func TestValidateLog_InvalidReward_NotGreaterThanValueNeeded(t *testing.T) {
	validator := NewValidator(cfg, srcChain)

	prevRewardAmount := parsedLog.Request.RewardAmount
	parsedLog.Request.RewardAmount = big.NewInt(1000000000000000000)
	defer func() { parsedLog.Request.RewardAmount = prevRewardAmount }()

	err := validator.ValidateLog(parsedLog)

	assert.Error(t, err)
}

func encodeBytes(bytesStr string) [32]byte {
	bytes, err := hex.DecodeString(bytesStr)
	if err != nil {
		log.Fatal(err)
	}

	var byteArray [32]byte
	copy(byteArray[32-len(bytes):], bytes)
	return byteArray
}
