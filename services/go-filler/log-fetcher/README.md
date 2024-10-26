# Log Fetcher

## Overview

The Log Fetcher serves as the first component in the RIP-7755 Fulfiller architecture. Its main purpose is to monitor events from `RIP7755Outbox` contracts on supported chains. When it ingests an event representing a cross-chain call request, it first parses the log into an ingestible format. It then validates the request by ensuring all routing information matches pre-defined chain configs for the source / destination chains. It then validates that the reward asset / amount represents a reward that would guarantee profit if this request were accepted by the system. If the request passes validation, the log fetcher passes it along to a Redis queue for further processing.

## Getting Started

Navigate to the `log-fetcher` directory:

```bash
cd services/go-filler/log-fetcher
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

Run the application:

```bash
go run ./cmd
```

Run unit tests:

```bash
go test ./internal/...
```
