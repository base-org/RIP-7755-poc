package validator

import (
	"errors"
	"math/big"

	"github.com/base-org/RIP-7755-poc/services/go-filler/bindings"
	"github.com/base-org/RIP-7755-poc/services/go-filler/log-fetcher/internal/chains"
	"github.com/base-org/RIP-7755-poc/services/go-filler/log-fetcher/internal/config"
	"github.com/ethereum/go-ethereum/common"
	logger "github.com/ethereum/go-ethereum/log"
)

type Validator interface {
	ValidateLog(*bindings.RIP7755OutboxCrossChainCallRequested) error
}

type validator struct {
	cfg      *config.Config
	srcChain *chains.ChainConfig
}

func NewValidator(cfg *config.Config, srcChain *chains.ChainConfig) Validator {
	return &validator{cfg: cfg, srcChain: srcChain}
}

func (v *validator) ValidateLog(log *bindings.RIP7755OutboxCrossChainCallRequested) error {
	logger.Info("Validating log")

	// - Confirm valid proverContract address on source chain
	dstChain, err := chains.GetChainConfig(log.Request.DestinationChainId, v.cfg.RPCs)
	if err != nil {
		return err
	}

	proverName := dstChain.TargetProver.String()
	if proverName == "" {
		return errors.New("destination chain missing Prover name")
	}

	expectedProverAddr := v.srcChain.ProverContracts[proverName]
	if expectedProverAddr == common.HexToAddress("") {
		return errors.New("expected prover address not found for source chain")
	}

	if log.Request.ProverContract != expectedProverAddr {
		return errors.New("unknown Prover contract")
	}

	// - Make sure inboxContract matches the trusted inbox for dst chain Id
	if log.Request.InboxContract != dstChain.Contracts.Inbox {
		return errors.New("unknown Inbox contract on destination chain")
	}

	// - Confirm l2Oracle and l2OracleStorageKey are valid for dst chain
	if log.Request.L2Oracle != dstChain.L2Oracle {
		return errors.New("unknown Oracle contract for destination chain")
	}
	if log.Request.L2OracleStorageKey != dstChain.L2OracleStorageKey {
		return errors.New("unknown storage key for dst L2Oracle")
	}

	// - Add up total value needed
	valueNeeded := big.NewInt(0)

	for i := 0; i < len(log.Request.Calls); i++ {
		valueNeeded.Add(valueNeeded, log.Request.Calls[i].Value)
	}

	// - rewardAsset + rewardAmount should make sense given requested calls
	if !isValidReward(&log.Request, valueNeeded) {
		return errors.New("undesirable reward")
	}

	return nil
}

func isValidReward(request *bindings.CrossChainRequest, valueNeeded *big.Int) bool {
	nativeAssetAddr := common.HexToAddress("0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE")
	isGreaterThan := request.RewardAmount.Cmp(valueNeeded) == 1

	return request.RewardAsset == nativeAssetAddr && isGreaterThan
}
