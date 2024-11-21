package listener

import (
	"context"
	"fmt"
	"math/big"
	"regexp"
	"sync"
	"time"

	"github.com/base-org/RIP-7755-poc/services/go-filler/bindings"
	"github.com/base-org/RIP-7755-poc/services/go-filler/log-fetcher/internal/chains"
	"github.com/base-org/RIP-7755-poc/services/go-filler/log-fetcher/internal/clients"
	"github.com/base-org/RIP-7755-poc/services/go-filler/log-fetcher/internal/handler"
	"github.com/base-org/RIP-7755-poc/services/go-filler/log-fetcher/internal/store"
	"github.com/ethereum/go-ethereum"
	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/common"
	logger "github.com/ethereum/go-ethereum/log"
)

type Listener interface {
	Start() error
	Stop()
}

type listener struct {
	outbox        *bindings.RIP7755Outbox
	handler       handler.Handler
	logs          chan *bindings.RIP7755OutboxCrossChainCallRequested
	stop          chan struct{}
	wg            sync.WaitGroup
	pollRate      time.Duration
	pollReqCh     chan struct{}
	polling       bool
	startingBlock uint64
	srcChainId    string
}

var httpRegex = regexp.MustCompile("^http(s)?://")

func NewListener(srcChainId *big.Int, networks chains.Networks, queue store.Queue, startingBlock uint64) (Listener, error) {
	srcChain, err := networks.GetChainConfig(srcChainId)
	if err != nil {
		return nil, err
	}

	h, err := handler.NewHandler(srcChain, networks, queue)
	if err != nil {
		return nil, err
	}

	contractAddress := srcChain.Contracts.Outbox
	if contractAddress == common.HexToAddress("") {
		return nil, fmt.Errorf("source chain %s missing Outbox contract address", srcChain.ChainId)
	}

	client, err := clients.GetEthClient(srcChain)
	if err != nil {
		return nil, fmt.Errorf("failed to get eth client: %v", err)
	}
	outbox, err := bindings.NewRIP7755Outbox(contractAddress, client)
	if err != nil {
		return nil, fmt.Errorf("failed to create Outbox contract binding: %v", err)
	}

	return &listener{
		outbox:        outbox,
		handler:       h,
		logs:          make(chan *bindings.RIP7755OutboxCrossChainCallRequested),
		stop:          make(chan struct{}),
		pollReqCh:     make(chan struct{}, 1),
		pollRate:      3 * time.Second,
		polling:       httpRegex.MatchString(srcChain.RpcUrl),
		startingBlock: startingBlock,
		srcChainId:    srcChainId.String(),
	}, nil
}

func (l *listener) Start() error {
	if l.polling {
		return pollListener(l)
	}

	return webSocketListener(l)
}

func webSocketListener(l *listener) error {
	sub, err := l.outbox.WatchCrossChainCallRequested(&bind.WatchOpts{Start: &l.startingBlock}, l.logs, [][32]byte{})
	if err != nil {
		return fmt.Errorf("failed to subscribe to logs: %v", err)
	}

	logger.Info("Subscribed to logs")

	l.wg.Add(1)
	go l.loop(sub)

	return nil
}

func pollListener(l *listener) error {
	logger.Info("Polling for logs")
	reqPollAfter := func() {
		if l.pollRate == 0 {
			return
		}
		time.AfterFunc(l.pollRate, l.reqPoll)
	}

	reqPollAfter()

	for {
		select {
		case <-l.pollReqCh:
			ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
			logIterator, err := l.outbox.FilterCrossChainCallRequested(&bind.FilterOpts{Context: ctx, Start: l.startingBlock}, [][32]byte{})
			if err != nil {
				logger.Error("failed to filter logs", "error", err)
				cancel()
				logIterator.Close()
				reqPollAfter()
				continue
			}

			for logIterator.Next() {
				err := logIterator.Error()
				if err != nil {
					logger.Error("error iterating over logs", "error", err)
					continue
				}

				log := logIterator.Event
				err = l.handler.HandleLog(l.srcChainId, log)
				if err != nil {
					logger.Error("failed to handle log", "error", err)
					continue
				}
			}

			cancel()
			logIterator.Close()
			reqPollAfter()
		case <-l.stop:
			return nil
		}
	}
}

func (l *listener) loop(sub ethereum.Subscription) {
	defer l.wg.Done()
	for {
		select {
		case err := <-sub.Err():
			logger.Info("Subscription error", "error", err)
		case log := <-l.logs:
			logger.Info("Log received!")
			logger.Info("Log Block Number", "blockNumber", log.Raw.BlockNumber)
			logger.Info("Log Index", "index", log.Raw.Index)

			err := l.handler.HandleLog(l.srcChainId, log)
			if err != nil {
				logger.Error("Error handling log", "error", err)
			}
		case <-l.stop:
			sub.Unsubscribe()
			return
		}
	}
}

func (l *listener) Stop() {
	close(l.stop)
	l.wg.Wait()
}

func (l *listener) reqPoll() {
	l.pollReqCh <- struct{}{}
}
