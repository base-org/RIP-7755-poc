package handler

import (
	"github.com/base-org/RIP-7755-poc/services/go-filler/bindings"
	"github.com/base-org/RIP-7755-poc/services/go-filler/log-fetcher/internal/chains"
	"github.com/base-org/RIP-7755-poc/services/go-filler/log-fetcher/internal/config"
	"github.com/base-org/RIP-7755-poc/services/go-filler/log-fetcher/internal/store"
	"github.com/base-org/RIP-7755-poc/services/go-filler/log-fetcher/internal/validator"
)

type Handler interface {
	HandleLog(*bindings.RIP7755OutboxCrossChainCallRequested) error
}

type handler struct {
	validator validator.Validator
	queue     store.Queue
}

func NewHandler(cfg *config.Config, srcChain *chains.ChainConfig, queue store.Queue) (Handler, error) {
	return &handler{validator: validator.NewValidator(cfg, srcChain), queue: queue}, nil
}

func (h *handler) HandleLog(log *bindings.RIP7755OutboxCrossChainCallRequested) error {
	err := h.validator.ValidateLog(log)
	if err != nil {
		return err
	}

	err = h.queue.Enqueue(log)
	if err != nil {
		return err
	}

	return nil
}
