package chains

import (
	"encoding/hex"
	"fmt"
	"math/big"

	"github.com/base-org/RIP-7755-poc/services/go-filler/log-fetcher/internal/config"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/log"
)

type Contracts struct {
	AnchorStateRegistry common.Address
	ArbRollup           common.Address
	L2MessagePasser     common.Address
	Inbox               common.Address
	Outbox              common.Address
}

type ChainConfig struct {
	ChainId            *big.Int
	ProverContracts    map[string]common.Address
	RpcUrl             string
	L2Oracle           common.Address
	L2OracleStorageKey [32]byte
	Contracts          *Contracts
	TargetProver       config.Prover
}

func GetChainConfig(chainId *big.Int, rpcConfig *config.RPCs) (*ChainConfig, error) {
	var chainConfig *ChainConfig

	switch chainId.Int64() {
	// Arbitrum Sepolia
	case 421614:
		provers := map[string]common.Address{
			config.OPStackProver.String(): common.HexToAddress("0x062fBdCfd17A0346D2A9d89FE233bbAdBd1DC14C"),
		}
		contracts := &Contracts{
			Inbox:  common.HexToAddress("0xeE962eD1671F655a806cB22623eEA8A7cCc233bC"),
			Outbox: common.HexToAddress("0xBCd5762cF9B07EF5597014c350CE2efB2b0DB2D2"),
		}

		chainConfig = &ChainConfig{
			ChainId:            chainId,
			ProverContracts:    provers,
			RpcUrl:             rpcConfig.ArbitrumSepolia,
			L2Oracle:           common.HexToAddress("0xd80810638dbDF9081b72C1B33c65375e807281C8"),
			L2OracleStorageKey: encodeBytes("0000000000000000000000000000000000000000000000000000000000000076"),
			Contracts:          contracts,
			TargetProver:       config.ArbitrumProver,
		}
	// Base Sepolia
	case 84532:
		provers := map[string]common.Address{
			config.ArbitrumProver.String(): common.HexToAddress("0x49E2cDC9e81825B6C718ae8244fe0D5b062F4874"),
			config.OPStackProver.String():  common.HexToAddress("0x562879614C9Db8Da9379be1D5B52BAEcDD456d78"),
		}
		contracts := &Contracts{
			Inbox:  common.HexToAddress("0xB482b292878FDe64691d028A2237B34e91c7c7ea"),
			Outbox: common.HexToAddress("0xD7a5A114A07cC4B5ebd9C5e1cD1136a99fFA3d68"),
		}

		chainConfig = &ChainConfig{
			ChainId:            chainId,
			ProverContracts:    provers,
			RpcUrl:             rpcConfig.BaseSepolia,
			L2Oracle:           common.HexToAddress("0x4C8BA32A5DAC2A720bb35CeDB51D6B067D104205"),
			L2OracleStorageKey: encodeBytes("a6eef7e35abe7026729641147f7915573c7e97b47efa546f5f6e3230263bcb49"),
			Contracts:          contracts,
			TargetProver:       config.OPStackProver,
		}
	// Optimism Sepolia
	case 11155420:
		provers := map[string]common.Address{}
		contracts := &Contracts{
			L2MessagePasser: common.HexToAddress("0x4200000000000000000000000000000000000016"),
			Inbox:           common.HexToAddress("0x49E2cDC9e81825B6C718ae8244fe0D5b062F4874"),
		}

		chainConfig = &ChainConfig{
			ChainId:            chainId,
			ProverContracts:    provers,
			RpcUrl:             rpcConfig.OptimismSepolia,
			L2Oracle:           common.HexToAddress("0x218CD9489199F321E1177b56385d333c5B598629"),
			L2OracleStorageKey: encodeBytes("a6eef7e35abe7026729641147f7915573c7e97b47efa546f5f6e3230263bcb49"),
			Contracts:          contracts,
			TargetProver:       config.OPStackProver,
		}
	// Sepolia
	case 11155111:
		provers := map[string]common.Address{}
		contracts := &Contracts{
			AnchorStateRegistry: common.HexToAddress("0x218CD9489199F321E1177b56385d333c5B598629"),
			ArbRollup:           common.HexToAddress("0xd80810638dbDF9081b72C1B33c65375e807281C8"),
		}

		chainConfig = &ChainConfig{
			ChainId:         chainId,
			ProverContracts: provers,
			RpcUrl:          rpcConfig.Sepolia,
			Contracts:       contracts,
			TargetProver:    config.NilProver,
		}
	default:
		return nil, fmt.Errorf("unknown chainId: %d", chainId.Int64())
	}

	return chainConfig, nil
}

func encodeBytes(bytesStr string) [32]byte {
	bytes, err := hex.DecodeString(bytesStr)
	if err != nil {
		log.Crit("Failed to decode bytes", "error", err)
	}

	var byteArray [32]byte
	copy(byteArray[32-len(bytes):], bytes)
	return byteArray
}
