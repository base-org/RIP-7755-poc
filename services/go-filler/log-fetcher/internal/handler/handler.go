package handler

import (
	"github.com/base-org/RIP-7755-poc/services/go-filler/log-fetcher/internal/chains"
	"github.com/base-org/RIP-7755-poc/services/go-filler/log-fetcher/internal/clients"
	"github.com/base-org/RIP-7755-poc/services/go-filler/log-fetcher/internal/config"
	"github.com/base-org/RIP-7755-poc/services/go-filler/log-fetcher/internal/parser"
	"github.com/base-org/RIP-7755-poc/services/go-filler/log-fetcher/internal/validator"
	"github.com/ethereum/go-ethereum/core/types"
)

func HandleLog(vLog types.Log, srcChain *chains.ChainConfig, cfg *config.Config) error {
	parsedLog, err := parser.ParseLog(vLog)
	if err != nil {
		return err
	}

	// validate Log
	err = validator.ValidateLog(cfg, srcChain, parsedLog)
	if err != nil {
		return err
	}

	// send log to queue
	queueClient := clients.GetQueueClient(cfg)
	err = queueClient.SendMessageToQueue(parsedLog, cfg)
	if err != nil {
		return err
	}

	return nil
}
