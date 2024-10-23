package config

import (
	"log"
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
	RPCs *RPCs
}

func NewConfig() *Config {
	if err := godotenv.Load(".env"); err != nil {
		log.Fatal("config file not found")
	}

	config := &Config{
		RPCs: &RPCs{
			ArbitrumSepolia: getEnvStr("ARBITRUM_SEPOLIA_RPC"),
			BaseSepolia:     getEnvStr("BASE_SEPOLIA_RPC"),
			OptimismSepolia: getEnvStr("OPTIMISM_SEPOLIA_RPC"),
			Sepolia:         getEnvStr("SEPOLIA_RPC"),
		},
	}

	return config
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
