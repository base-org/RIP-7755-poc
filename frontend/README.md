# Ethereum Bridge Application

## Overview

This application demonstrates a practical use-case for the RIP-7755 protocol, acting as an Ethereum bridge between the Arbitrum Sepolia and Base Sepolia networks. It enables fast, seamless, and permissionless transfers of ETH, highlighting the protocol's potential for real-world applications.

## Key Features

- **High Speed**:  Achieves a latency of just 6 seconds, significantly faster than most existing bridging solutions.
- **Permissionless**: Operates without requiring special permissions or trust assumptions, ensuring accessibility for all users.

## Prerequisites

To ensure proper functionality, the following prerequisites must be met:

1. **Backend Service**: The backend service in the services/ts-filler directory must be running. This service handles critical backend operations for the bridge.
2. **Wallet Setup**: Install Coinbase Wallet in your browser to interact with the Ethereum networks. Ensure it is connected and configured.

## Setup Instructions

1. **Clone the Repository**: Clone the repository to your local machine using the following command:

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

Once the application is running, access it through your browser. Follow these steps:

1. **Connect Your Wallet**: Use Coinbase Wallet to connect to the Ethereum networks.
2. **Select Source and Destination Networks**: Choose **Arbitrum Sepolia** and **Base Sepolia** as the source and destination networks.
3. **Bridge ETH**: Specify the amount of ETH you wish to transfer and confirm the transaction.

---

## Additional Information

- Ensure both the backend service and frontend application are running simultaneously for full functionality.
- For production deployment, consult the [Deployment Guide](../../deployment/README.md) or follow your organization's deployment pipeline.

By following these steps, you can seamlessly bridge ETH between networks and experience the power of the RIP-7755 protocol in action.