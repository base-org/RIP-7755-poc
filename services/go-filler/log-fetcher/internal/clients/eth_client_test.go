package clients

import (
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/base-org/RIP-7755-poc/services/go-filler/log-fetcher/internal/chains"
	"github.com/stretchr/testify/assert"
)

func TestGetClient(t *testing.T) {
	t.Run("successful connection", func(t *testing.T) {
		// Create a mock HTTP server
		server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			w.WriteHeader(http.StatusOK)
		}))
		defer server.Close()

		// Create a chain config with the mock server URL
		cfg := &chains.ChainConfig{
			RpcUrl: server.URL,
		}

		// Call GetClient
		client, err := GetEthClient(cfg)

		// Assert
		assert.NoError(t, err)
		assert.NotNil(t, client)
	})

	t.Run("failed connection", func(t *testing.T) {
		// Create a chain config with an invalid URL
		cfg := &chains.ChainConfig{
			RpcUrl: "invalid-url",
		}

		// Call GetClient
		client, err := GetEthClient(cfg)

		// Assert
		assert.Error(t, err)
		assert.Nil(t, client)
	})
}
