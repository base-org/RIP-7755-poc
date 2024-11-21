package validator

import (
	"math/big"
	"testing"

	"github.com/base-org/RIP-7755-poc/services/go-filler/bindings"
	"github.com/base-org/RIP-7755-poc/services/go-filler/log-fetcher/internal/chains"
	"github.com/base-org/RIP-7755-poc/services/go-filler/log-fetcher/internal/provers"
	"github.com/ethereum/go-ethereum/common"
	"github.com/stretchr/testify/assert"
)

var networksCfg chains.NetworksConfig = chains.NetworksConfig{
	Networks: chains.Networks{
		"421614": chains.ChainConfig{
			ProverContracts: map[string]common.Address{
				"OPStackProver": common.HexToAddress("0x1234567890123456789012345678901234567890"),
			},
		},
		"84532": chains.ChainConfig{
			Contracts: &chains.Contracts{
				Inbox: common.HexToAddress("0xB482b292878FDe64691d028A2237B34e91c7c7ea"),
			},
			L2Oracle:           common.HexToAddress("0x4C8BA32A5DAC2A720bb35CeDB51D6B067D104205"),
			L2OracleStorageKey: "0xa6eef7e35abe7026729641147f7915573c7e97b47efa546f5f6e3230263bcb49",
			TargetProver:       provers.OPStackProver,
		},
	},
}

var srcChain = &chains.ChainConfig{
	ChainId: big.NewInt(421614),
	ProverContracts: map[string]common.Address{
		"OPStackProver": common.HexToAddress("0x1234567890123456789012345678901234567890"),
	},
}

var parsedLog = &bindings.RIP7755OutboxCrossChainCallRequested{
	Request: bindings.CrossChainRequest{
		Calls: []bindings.Call{
			{
				To:    common.HexToAddress("0x1234567890123456789012345678901234567890"),
				Value: big.NewInt(1000000000000000000),
			},
		},
		DestinationChainId: big.NewInt(84532),
		InboxContract:      common.HexToAddress("0xB482b292878FDe64691d028A2237B34e91c7c7ea"),
		L2Oracle:           common.HexToAddress("0x4C8BA32A5DAC2A720bb35CeDB51D6B067D104205"),
		L2OracleStorageKey: common.HexToHash("0xa6eef7e35abe7026729641147f7915573c7e97b47efa546f5f6e3230263bcb49"),
		ProverContract:     common.HexToAddress("0x1234567890123456789012345678901234567890"),
		RewardAsset:        common.HexToAddress("0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE"),
		RewardAmount:       big.NewInt(2000000000000000000),
	},
}

func TestValidateLog(t *testing.T) {
	validator := NewValidator(srcChain, networksCfg.Networks)

	err := validator.ValidateLog(parsedLog)

	assert.NoError(t, err)
}

func TestValidateLog_UnknownDestinationChain(t *testing.T) {
	validator := NewValidator(srcChain, networksCfg.Networks)

	prevDstChainId := parsedLog.Request.DestinationChainId
	parsedLog.Request.DestinationChainId = big.NewInt(11155112)
	defer func() { parsedLog.Request.DestinationChainId = prevDstChainId }()

	err := validator.ValidateLog(parsedLog)

	assert.Error(t, err)
}

func TestValidateLog_UnknownProverName(t *testing.T) {
	validator := NewValidator(srcChain, networksCfg.Networks)

	prevDstChainId := parsedLog.Request.DestinationChainId
	parsedLog.Request.DestinationChainId = big.NewInt(11155111)
	defer func() { parsedLog.Request.DestinationChainId = prevDstChainId }()

	err := validator.ValidateLog(parsedLog)

	assert.Error(t, err)
}

func TestValidateLog_UnknownProverContract(t *testing.T) {
	validator := NewValidator(srcChain, networksCfg.Networks)

	prevProverContract := parsedLog.Request.ProverContract
	parsedLog.Request.ProverContract = common.HexToAddress("0x1234567890123456789012345678901234567891")
	defer func() { parsedLog.Request.ProverContract = prevProverContract }()

	err := validator.ValidateLog(parsedLog)

	assert.Error(t, err)
}

func TestValidateLog_UnknownInboxContract(t *testing.T) {
	validator := NewValidator(srcChain, networksCfg.Networks)

	prevInboxContract := parsedLog.Request.InboxContract
	parsedLog.Request.InboxContract = common.HexToAddress("0x1234567890123456789012345678901234567891")
	defer func() { parsedLog.Request.InboxContract = prevInboxContract }()

	err := validator.ValidateLog(parsedLog)

	assert.Error(t, err)
}

func TestValidateLog_UnknownL2Oracle(t *testing.T) {
	validator := NewValidator(srcChain, networksCfg.Networks)

	prevL2Oracle := parsedLog.Request.L2Oracle
	parsedLog.Request.L2Oracle = common.HexToAddress("0x1234567890123456789012345678901234567891")
	defer func() { parsedLog.Request.L2Oracle = prevL2Oracle }()

	err := validator.ValidateLog(parsedLog)

	assert.Error(t, err)
}

func TestValidateLog_UnknownL2OracleStorageKey(t *testing.T) {
	validator := NewValidator(srcChain, networksCfg.Networks)

	prevL2OracleStorageKey := parsedLog.Request.L2OracleStorageKey
	parsedLog.Request.L2OracleStorageKey = common.HexToHash("0x1234567890123456789012345678901234567891")
	defer func() { parsedLog.Request.L2OracleStorageKey = prevL2OracleStorageKey }()

	err := validator.ValidateLog(parsedLog)

	assert.Error(t, err)
}

func TestValidateLog_InvalidReward_NotNativeAsset(t *testing.T) {
	validator := NewValidator(srcChain, networksCfg.Networks)

	prevRewardAsset := parsedLog.Request.RewardAsset
	parsedLog.Request.RewardAsset = common.HexToAddress("0x1234567890123456789012345678901234567891")
	defer func() { parsedLog.Request.RewardAsset = prevRewardAsset }()

	err := validator.ValidateLog(parsedLog)

	assert.Error(t, err)
}

func TestValidateLog_InvalidReward_NotGreaterThanValueNeeded(t *testing.T) {
	validator := NewValidator(srcChain, networksCfg.Networks)

	prevRewardAmount := parsedLog.Request.RewardAmount
	parsedLog.Request.RewardAmount = big.NewInt(1000000000000000000)
	defer func() { parsedLog.Request.RewardAmount = prevRewardAmount }()

	err := validator.ValidateLog(parsedLog)

	assert.Error(t, err)
}
