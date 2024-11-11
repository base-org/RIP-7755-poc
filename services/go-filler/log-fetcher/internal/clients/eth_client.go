package clients

import (
	"github.com/base-org/RIP-7755-poc/services/go-filler/log-fetcher/internal/chains"
	"github.com/ethereum/go-ethereum/ethclient"
	"github.com/ethereum/go-ethereum/log"
)

func GetEthClient(cfg *chains.ChainConfig) (*ethclient.Client, error) {
	client, err := ethclient.Dial(cfg.RpcUrl)
	if err != nil {
		return nil, err
	}

	log.Info("Connected to client", "url", cfg.RpcUrl)

	return client, nil
}
