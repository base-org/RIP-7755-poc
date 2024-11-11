package config

import (
	"log"
	"math/big"
	"os"

	"github.com/joho/godotenv"
)

type RPCs struct {
	ArbitrumSepolia string
	BaseSepolia     string
	OptimismSepolia string
	Sepolia         string
}

type Config struct {
	RPCs            *RPCs
	MongoUri        string
	SupportedChains []*big.Int
}

func NewConfig() (*Config, error) {
	if err := godotenv.Load(".env"); err != nil {
		return nil, err
	}

	config := &Config{
		RPCs: &RPCs{
			ArbitrumSepolia: getEnvStr("ARBITRUM_SEPOLIA_RPC"),
			BaseSepolia:     getEnvStr("BASE_SEPOLIA_RPC"),
			OptimismSepolia: getEnvStr("OPTIMISM_SEPOLIA_RPC"),
			Sepolia:         getEnvStr("SEPOLIA_RPC"),
		},
		MongoUri:        getEnvStr("MONGO_URI"),
		SupportedChains: []*big.Int{big.NewInt(421614)},
	}

	return config, nil
}

// getEnvStr ... Reads env var from process environment, panics if not found
func getEnvStr(key string) string {
	envVar, ok := os.LookupEnv(key)

	// Not found
	if !ok {
		log.Fatalf("could not find env var given key: %s", key)
	}

	return envVar
}
