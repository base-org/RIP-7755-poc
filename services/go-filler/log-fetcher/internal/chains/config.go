package chains

import (
	"fmt"
	"math/big"

	"github.com/base-org/RIP-7755-poc/services/go-filler/log-fetcher/internal/config"
	"github.com/ethereum/go-ethereum/common"
)

type NetworksConfig struct {
	Networks Networks `yaml:"networks"`
}
type Networks map[string]ChainConfig

type Contracts struct {
	AnchorStateRegistry common.Address `yaml:"anchor-state-registry"`
	ArbRollup           common.Address `yaml:"arb-rollup"`
	L2MessagePasser     common.Address `yaml:"l2-message-passer"`
	Inbox               common.Address `yaml:"inbox"`
	Outbox              common.Address `yaml:"outbox"`
}

type ChainConfig struct {
	ChainId            *big.Int                  `yaml:"chain-id"`
	ProverContracts    map[string]common.Address `yaml:"prover-contracts"`
	RpcUrl             string                    `yaml:"rpc-url"`
	L2Oracle           common.Address            `yaml:"l2-oracle"`
	L2OracleStorageKey string                    `yaml:"l2-oracle-storage-key"`
	Contracts          *Contracts                `yaml:"contracts"`
	TargetProver       config.Prover             `yaml:"target-prover"`
}

func (n *Networks) GetChainConfig(chainId *big.Int) (*ChainConfig, error) {
	chainConfig, ok := (*n)[chainId.String()]
	if !ok {
		return nil, fmt.Errorf("unknown chainId: %d", chainId.Int64())
	}

	return &chainConfig, nil
}
