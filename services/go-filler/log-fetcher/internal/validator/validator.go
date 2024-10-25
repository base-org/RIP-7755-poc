package validator

import (
	"errors"
	"fmt"
	"math/big"

	"github.com/base-org/RIP-7755-poc/services/go-filler/log-fetcher/internal/chains"
	"github.com/base-org/RIP-7755-poc/services/go-filler/log-fetcher/internal/config"
	"github.com/base-org/RIP-7755-poc/services/go-filler/log-fetcher/internal/parser"
	"github.com/ethereum/go-ethereum/common"
)

type Validator interface {
	ValidateLog(cfg *config.Config, srcChain *chains.ChainConfig, parsedLog parser.LogCrossChainCallRequested) error
}

type validator struct{}

func NewValidator() Validator {
	return &validator{}
}

func (v *validator) ValidateLog(cfg *config.Config, srcChain *chains.ChainConfig, parsedLog parser.LogCrossChainCallRequested) error {
	fmt.Println("Validating log")

	// - Confirm valid proverContract address on source chain
	dstChain, err := chains.GetChainConfig(parsedLog.Request.DestinationChainId, cfg.RPCs)
	if err != nil {
		return err
	}

	proverName := dstChain.TargetProver.String()
	if proverName == "" {
		return errors.New("destination chain missing Prover name")
	}

	expectedProverAddr := srcChain.ProverContracts[proverName]
	if expectedProverAddr == common.HexToAddress("") {
		return errors.New("expected prover address not found for source chain")
	}

	if parsedLog.Request.ProverContract != expectedProverAddr {
		return errors.New("unknown Prover contract")
	}

	// - Make sure inboxContract matches the trusted inbox for dst chain Id
	if parsedLog.Request.InboxContract != dstChain.Contracts.Inbox {
		return errors.New("unknown Inbox contract on destination chain")
	}

	// - Confirm l2Oracle and l2OracleStorageKey are valid for dst chain
	if parsedLog.Request.L2Oracle != dstChain.L2Oracle {
		return errors.New("unknown Oracle contract for destination chain")
	}
	if parsedLog.Request.L2OracleStorageKey != dstChain.L2OracleStorageKey {
		return errors.New("unknown storage key for dst L2Oracle")
	}

	// - Add up total value needed
	valueNeeded := big.NewInt(0)

	for i := 0; i < len(parsedLog.Request.Calls); i++ {
		valueNeeded.Add(valueNeeded, parsedLog.Request.Calls[i].Value)
	}

	// - rewardAsset + rewardAmount should make sense given requested calls
	if !isValidReward(parsedLog.Request, valueNeeded) {
		return errors.New("undesirable reward")
	}

	return nil
}

func isValidReward(request parser.CrossChainRequest, valueNeeded *big.Int) bool {
	nativeAssetAddr := common.HexToAddress("0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE")
	isGreaterThan := request.RewardAmount.Cmp(valueNeeded) == 1

	return request.RewardAsset == nativeAssetAddr && isGreaterThan
}
