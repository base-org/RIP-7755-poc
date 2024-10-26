package handler

import (
	"github.com/base-org/RIP-7755-poc/services/go-filler/log-fetcher/internal/chains"
	"github.com/base-org/RIP-7755-poc/services/go-filler/log-fetcher/internal/config"
	"github.com/base-org/RIP-7755-poc/services/go-filler/log-fetcher/internal/parser"
	"github.com/base-org/RIP-7755-poc/services/go-filler/log-fetcher/internal/store"
	"github.com/base-org/RIP-7755-poc/services/go-filler/log-fetcher/internal/validator"
	"github.com/ethereum/go-ethereum/core/types"
)

type Handler interface {
	HandleLog(vLog types.Log) error
}

type handler struct {
	cfg       *config.Config
	srcChain  *chains.ChainConfig
	parser    parser.Parser
	validator validator.Validator
	queue     store.MongoConnection
}

func NewHandler(cfg *config.Config, srcChain *chains.ChainConfig, queue store.MongoConnection) Handler {
	return &handler{cfg: cfg, srcChain: srcChain, parser: parser.NewParser(), validator: validator.NewValidator(), queue: queue}
}

func (h *handler) HandleLog(vLog types.Log) error {
	parsedLog, err := h.parser.ParseLog(vLog)
	if err != nil {
		return err
	}

	err = h.validator.ValidateLog(h.cfg, h.srcChain, parsedLog)
	if err != nil {
		return err
	}

	err = h.queue.Enqueue(parsedLog, h.cfg)
	if err != nil {
		return err
	}

	return nil
}
