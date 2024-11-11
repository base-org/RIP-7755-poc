# An Example Fulfiller App implemented in Go

## Getting Started

Navigate to the `go-filler` directory:

```bash
cd services/go-filler
```

Install dependencies:

```bash
go mod tidy
```

Spin up the docker containers:

```bash
docker-compose up -d
```

Create a `.env` file (the rpc urls must be websocket):

```txt
ARBITRUM_SEPOLIA_RPC=
BASE_SEPOLIA_RPC=
OPTIMISM_SEPOLIA_RPC=
SEPOLIA_RPC=
MONGO_URI=
```

### Log Fetcher

Run the log fetcher:

```bash
go run ./log-fetcher/cmd
```

Run log fetcher unit tests:

```bash
go test ./log-fetcher/internal/...
```
