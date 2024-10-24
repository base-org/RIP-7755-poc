package handler

import (
	"log"

	"github.com/base-org/RIP-7755-poc/services/go-filler/log-fetcher/internal/chains"
	"github.com/base-org/RIP-7755-poc/services/go-filler/log-fetcher/internal/config"
	"github.com/base-org/RIP-7755-poc/services/go-filler/log-fetcher/internal/parser"
	"github.com/base-org/RIP-7755-poc/services/go-filler/log-fetcher/internal/queue"
	"github.com/base-org/RIP-7755-poc/services/go-filler/log-fetcher/internal/validator"
	"github.com/ethereum/go-ethereum/core/types"
)

func HandleLog(vLog types.Log, srcChain *chains.ChainConfig, cfg *config.Config) error {
	parsedLog, err := parser.ParseLog(vLog)
	if err != nil {
		log.Fatal(err)
	}

	// validate Log
	err = validator.ValidateLog(cfg, srcChain, parsedLog)
	if err != nil {
		log.Fatal(err)
	}

	// send log to queue
	err = queue.SendMessage(parsedLog, cfg)
	if err != nil {
		log.Fatal(err)
	}

	return nil
}
