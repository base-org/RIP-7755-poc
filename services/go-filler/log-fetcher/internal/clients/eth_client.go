package clients

import (
	"fmt"

	"github.com/base-org/RIP-7755-poc/services/go-filler/log-fetcher/internal/chains"
	"github.com/ethereum/go-ethereum/ethclient"
)

func GetEthClient(cfg *chains.ChainConfig) (*ethclient.Client, error) {
	client, err := ethclient.Dial(cfg.RpcUrl)
	if err != nil {
		return nil, err
	}

	fmt.Println("Connected to client")

	return client, nil
}
