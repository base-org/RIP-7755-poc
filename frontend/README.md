# Ethereum Bridge Application

## Overview

This application demonstrates a fundamental use-case empowered by the RIP-7755 protocol. It serves as an Ethereum bridge between the Arbitrum Sepolia and Base Sepolia networks. The bridge facilitates fast and permissionless transfers of ETH between these two networks, showcasing the potential of RIP-7755 in real-world applications.

## Key Features

- **High Speed**: The bridge implementation is exceptionally fast, achieving a latency of just 6 seconds, which is significantly quicker than most existing bridging solutions.
- **Permissionless**: The bridge operates without requiring any special permissions or trust assumptions, making it accessible to all users.

## Prerequisites

To ensure the application functions correctly, the following prerequisites must be met:

1. **Running Backend Service**: The application in the [`services/ts-filler`](../../services/ts-filler) directory must be running. This service handles the backend operations necessary for the bridge to function.
2. **Coinbase Wallet**: It is recommended to have [Coinbase Wallet](https://www.coinbase.com/wallet) installed in your browser. This wallet will be used to interact with the Ethereum networks.

## Setup Instructions

1. **Clone the Repository**: Clone the repository to your local machine.

   ```sh
   git clone <repository-url>
   ```

2. **Navigate to the Frontend Directory**: Change to the `frontend` directory.

   ```sh
   cd frontend
   ```

3. **Install Dependencies**: Install the necessary dependencies using npm.

   ```sh
   npm install
   ```

4. **Configure Environment Variables**: Ensure that the `.env` file in the `frontend` directory is properly configured with the required environment variables.

   ```txt
   NEXT_PUBLIC_ONCHAINKIT_PROJECT_NAME=frontend
   NEXT_PUBLIC_ONCHAINKIT_CDP_KEY=<Your Coinbase Developer Portal Project ID>
   NEXT_PUBLIC_ONCHAINKIT_WALLET_CONFIG=all
   ```

5. **Run the Backend Service**: Navigate to the `services/ts-filler` directory and start the backend service. See [Fulfiller README](../services/ts-filler/README.md).

6. **Start the Frontend Application**: Return to the `frontend` directory and start the application.
   ```sh
   cd ../../frontend
   npm run dev
   ```

## Usage

Once the application is running, you can access it via your web browser. Use Coinbase Wallet to connect to the Ethereum networks and start bridging ETH between Arbitrum Sepolia and Base Sepolia.
