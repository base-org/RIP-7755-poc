package flags

import (
	"github.com/urfave/cli/v2"
)

var (
	MongoUriFlag = &cli.StringFlag{
		Name:     "mongo-uri",
		Usage:    "Connection string to MongoDB",
		EnvVars:  []string{"MONGO_URI"},
		Required: true,
	}
	ArbitrumSepoliaRpcFlag = &cli.StringFlag{
		Name:     "arbitrum-sepolia-rpc",
		Usage:    "Arbitrum Sepolia RPC",
		EnvVars:  []string{"ARBITRUM_SEPOLIA_RPC"},
		Required: true,
	}
	BaseSepoliaRpcFlag = &cli.StringFlag{
		Name:     "base-sepolia-rpc",
		Usage:    "Base Sepolia RPC",
		EnvVars:  []string{"BASE_SEPOLIA_RPC"},
		Required: true,
	}
	OptimismSepoliaRpcFlag = &cli.StringFlag{
		Name:     "optimism-sepolia-rpc",
		Usage:    "Optimism Sepolia RPC",
		EnvVars:  []string{"OPTIMISM_SEPOLIA_RPC"},
		Required: true,
	}
	SepoliaRpcFlag = &cli.StringFlag{
		Name:     "sepolia-rpc",
		Usage:    "Sepolia RPC",
		EnvVars:  []string{"SEPOLIA_RPC"},
		Required: true,
	}
	SupportedChainsFlag = &cli.StringSliceFlag{
		Name:     "supported-chains",
		Usage:    "Comma separated list of supported chains",
		Value:    cli.NewStringSlice("421614"),
		EnvVars:  []string{"SUPPORTED_CHAINS"},
		Required: false,
	}
)

// Flags contains the list of configuration options available to the binary.
var Flags = []cli.Flag{MongoUriFlag, ArbitrumSepoliaRpcFlag, BaseSepoliaRpcFlag, OptimismSepoliaRpcFlag, SepoliaRpcFlag, SupportedChainsFlag}
