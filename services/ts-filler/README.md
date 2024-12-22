# ts-filler

## Overview

`ts-filler` is a backend service built with the Bun JavaScript runtime. It is designed to manage backend operations for RIP-7755 cross-chain call requests between any two blockchains that post state roots to L1. This project serves as an example of how an off-chain "Fulfiller" app might function. Anyone can run a fulfiller app and earn money with RIP-7755!

The role of an RIP-7755 Fulfiller is to listen for cross-chain call requests and submit them to the `RIP7755Inbox` contract on the destination chain on behalf of the user who submitted the request. In return for fulfilling this duty, your fulfiller signer can claim a reward that gets locked in the source chain `RIP7755Outbox` contract after a defined delay specified in the `CrossChainRequest`. To claim the reward, the fulfiller must generate and submit a proof that verifies the existence of a record of the call having been made in `RIP7755Inbox` on the destination chain. The exact proof mechanics depend on the destination chain. Currently, only Arbitrum and OP Stack chains are supported.

## Prerequisites

Before you begin, ensure you have met the following requirements:

- **Bun**: Install Bun v1.1.29 or later. You can download it from [Bun's official website](https://bun.sh).

## Installation

To install the necessary dependencies, follow these steps:

1. **Clone the Repository**: Clone the repository to your local machine.

   ```bash
   git clone <repository-url>
   ```

2. **Navigate to the `ts-filler` Directory**: Change to the `ts-filler` directory.

   ```bash
   cd services/ts-filler
   ```

3. **Install Dependencies**: Use Bun to install the dependencies.

   ```bash
   bun install
   ```

4. **Configure Environment Variables**: Ensure that the `.env` file in the `services/ts-filler` directory is properly configured with the required environment variables.

   ```txt
   NODE=<An Ethereum Beacon Node API URL. Can get from a provider like QuickNode>
   ARBITRUM_SEPOLIA_RPC=<An RPC URL for Arbitrum Sepolia>
   BASE_SEPOLIA_RPC=<An RPC URL for Base Sepolia>
   SEPOLIA_RPC=<An RPC URL for Sepolia>
   MONGO_URI=<A MongoDB connection string>
   ARBISCAN_API_KEY=<An API key for the Arbiscan API see https://docs.arbiscan.io/getting-started/viewing-api-usage-statistics>
   ETHERSCAN_API_KEY=<An API key for the Etherscan API>
   BASESCAN_API_KEY=<An API key for the BaseScan API>
   OPTIMISM_API_KEY=<An API key for the Optimism Etherscan API>
   PRIVATE_KEY=<A wallet private key for the signer that will be submitting transactions / claiming rewards>
   ```

## Running the Service

To run the backend service, use the following command:

```bash
bun run index.ts
```

## Docker Support

The `ts-filler` service can also be run inside a Docker container. The provided `docker-compose.yml` file sets up the environment and installs the necessary dependencies.

To build and run the Docker container, use the following command:

1. **Build & Run the Docker Container**:

   ```bash
   docker-compose up -d
   ```

## Fulfiller App Requirements

Running a Fulfiller app in the RIP-7755 ecosystem has minimal requirements, but there are essential guidelines to ensure security and proper functionality:

- **Funded Signer**: Ensure the signer used to broadcast transactions is funded with the native currency of the blockchains you intend to support.
- **Address Validation**: Do not trust addresses in the `Request` structure from `CrossChainCallRequested` events without validating them against the configured chain [settings](./src/chain/chains.ts).
- **Reward Verification**: Verify that the `rewardAsset` and `rewardAmount` are appropriate given the requested transaction.
- **Robust Monitoring**: Implement robust monitoring to track successfully submitted calls. After a call is successfully submitted, wait for `request.finalityDelaySeconds` before claiming your reward from the source chain `RIP7755Outbox` contract. If you do not claim the reward, the user can reclaim it after a 1-day delay.

## License

This project is licensed under the MIT License. See the [LICENSE](../../LICENSE) file for more details.
