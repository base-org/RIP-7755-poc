package handler

import (
	"github.com/base-org/RIP-7755-poc/services/go-filler/log-fetcher/internal/chains"
	"github.com/base-org/RIP-7755-poc/services/go-filler/log-fetcher/internal/config"
	"github.com/base-org/RIP-7755-poc/services/go-filler/log-fetcher/internal/parser"
	"github.com/base-org/RIP-7755-poc/services/go-filler/log-fetcher/internal/store"
	"github.com/base-org/RIP-7755-poc/services/go-filler/log-fetcher/internal/validator"
	"github.com/ethereum/go-ethereum/core/types"
)

func HandleLog(vLog types.Log, srcChain *chains.ChainConfig, cfg *config.Config, mongoClient store.MongoClient) error {
	parsedLog, err := parser.ParseLog(vLog)
	if err != nil {
		return err
	}

	// validate Log
	v := validator.NewValidator()
	err = v.ValidateLog(cfg, srcChain, parsedLog)
	if err != nil {
		return err
	}

	// send log to queue
	c := mongoClient.Collection("requests")
	err = c.Enqueue(parsedLog, cfg)
	if err != nil {
		return err
	}

	return nil
}
