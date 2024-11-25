![Base](logo.webp)

# RIP-7755

## Overview

RIP-7755 is a work-in-progress [proposal](https://github.com/ethereum/RIPs/pull/31) aimed at standardizing permissionless cross-chain transactions between any two chains that post state roots to Ethereum. The architecture of RIP-7755 is relatively straightforward. It involves portal contracts on both the source and destination chains, as well as an off-chain relayer system. While this is similar to many existing solutions, the key distinction is that the off-chain relayer system is _permissionless_ and supports any arbitrary set of calls. In this proposal, the off-chain agent is referred to as a “Fulfiller,” and anyone can operate a fulfiller agent.

The three main components of RIP-7755 are:

1. Source chain portal: `RIP7755Outbox`
2. Off-chain relayer: `Fulfiller`
3. Destination chain portal: `RIP7755Inbox`

A core feature of RIP-7755 is to incentivize individuals to act as fulfillers. When a user submits a request to the protocol for a cross-chain call, they must also provide a “reward” or “tip” for the fulfiller, similar to priority gas fees for Ethereum validators. This reward covers the gas cost of submitting the transaction to the destination chain and includes a small tip for the fulfiller's service. Fulfillers monitor cross-chain call requests from any supported chains. Upon validating a received request and confirming that the reward ensures a profit, the fulfiller submits the requested call to the destination chain. Once the call settles on the destination chain, the fulfiller can claim the reward, which is held in escrow, from the source chain.

To claim the reward, the fulfiller must _prove_ that they have successfully submitted the correct call to the correct destination. This highlights an important prerequisite for the chains supported by this protocol: both chains must post state roots (or derivatives of their state roots) to Ethereum. This provides the necessary building blocks to trustlessly prove the state of one chain from the other. In our early proof of concepts, we use storage proofs to achieve this.

A successful storage proof from the source chain should follow these steps:

1. Query the latest Beacon root exposed to the chain via EIP-4788.
2. Prove knowledge of the execution client state root, which should be a member of the Merkle trie that generated the Beacon root.
3. Use the execution state root to prove an account’s storage root. Here, the “account” refers to the contract where the destination chain posts its state root on L1.
4. Prove the state root’s storage location within that account.
5. Use the destination chain's state root to prove an account’s storage root. In this context, the “account” is the `RIP7755Inbox` contract on the destination chain.
6. Prove the storage slot in `RIP7755Inbox` that represents a receipt of the requested call having been made.

We use Storage Proofs in this manner to validate state for early iterations of a proof-of-concept for the protocol. However, this is not the only method available. To maintain flexibility for the future, potentially more efficient or easier-to-implement solutions, we have abstracted the proof system from the `RIP7755Inbox` and `RIP7755Outbox` contracts.

## License

This project is licensed under the MIT License.
