package config

import (
	"math/big"
	"os"
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestNewConfig(t *testing.T) {
	// Setup test environment variables
	os.Setenv("ARBITRUM_SEPOLIA_RPC", "https://arbitrum-sepolia.example.com")
	os.Setenv("BASE_SEPOLIA_RPC", "https://base-sepolia.example.com")
	os.Setenv("OPTIMISM_SEPOLIA_RPC", "https://optimism-sepolia.example.com")
	os.Setenv("SEPOLIA_RPC", "https://sepolia.example.com")
	os.Setenv("MONGO_URI", "mongodb://localhost:27017/db")

	// Create a temporary .env file
	envContent := `
ARBITRUM_SEPOLIA_RPC=https://arbitrum-sepolia.example.com
BASE_SEPOLIA_RPC=https://base-sepolia.example.com
OPTIMISM_SEPOLIA_RPC=https://optimism-sepolia.example.com
SEPOLIA_RPC=https://sepolia.example.com
MONGO_URI=mongodb://localhost:27017/db
`
	err := os.WriteFile(".env", []byte(envContent), 0644)
	assert.NoError(t, err)
	defer os.Remove(".env")

	// Test NewConfig
	config, err := NewConfig()

	assert.NoError(t, err)

	assert.NotNil(t, config)
	assert.NotNil(t, config.RPCs)
	assert.Equal(t, "https://arbitrum-sepolia.example.com", config.RPCs.ArbitrumSepolia)
	assert.Equal(t, "https://base-sepolia.example.com", config.RPCs.BaseSepolia)
	assert.Equal(t, "https://optimism-sepolia.example.com", config.RPCs.OptimismSepolia)
	assert.Equal(t, "https://sepolia.example.com", config.RPCs.Sepolia)
	assert.Equal(t, "mongodb://localhost:27017/db", config.MongoUri)
	assert.Equal(t, []*big.Int{big.NewInt(421614)}, config.SupportedChains)
}

func TestNewConfigMissingEnvVar(t *testing.T) {
	// Ensure no environment variables are set
	os.Clearenv()

	_, err := NewConfig()
	if err == nil {
		t.Fatal("expected an error due to missing environment variables, got none")
	}
}
