# RIP-7755

## Overview

There currently exist many solutions for sending transactions between two blockchains. Just about all solutions require portal contracts to be deployed on the source and destination chains as well as some sort of trusted off-chain protocol that is outside of Ethereum's core ecosystem. RIP-7755 is a WIP [proposal](https://github.com/ethereum/RIPs/pull/31) for standardized, permissionless cross-chain transactions between any two chains that post state roots to Ethereum. At a high level, the RIP-7755 architecture looks similar to existing solutions. It too needs portal contracts on the source and destination chains as well as an off-chain relayer system; however, the key difference here is the off-chain relayer system is _permissionless_. In the proposal, we’re calling an off-chain agent a “Fulfiller” and anyone can run a Fulfiller agent.

The three main components of RIP-7755 are:

1. Source chain portal: Called `RIP7755Outbox`
1. Off-chain relayer: Called `Fulfiller`
1. Destination chain portal: Called `RIP7755Inbox`

Now, you might ask “Why would someone want to run a Fulfiller agent?”. This leads us into a core feature of RIP-7755. When submitting a request to the protocol for a cross-chain call, the user must also submit a “reward” or “tip” for the fulfiller; similar in concept to priority gas fees for Ethereum validators. This reward is meant to cover the gas cost of submitting the transaction to the destination chain plus a small tip for the Fulfiller's service. Fulfillers shall be listening for cross-chain call requests from any supported chains - upon request validation and confirming the reward secures profit for the Fulfiller, the agent then submits the requested call to the destination chain. Once the destination chain call settles, the fulfiller can claim the reward, which is locked in escrow, from the source chain.

What if the fulfiller never submits the call to the destination chain or submits it to the wrong destination chain? Can they lie about it and claim the reward anyways? Another great question, and this is where the most important component of RIP-7755 comes into play. In order to claim the reward, the fulfiller needs to _prove_ that they successfully submitted the correct call to the correct destination. Only then can they claim their reward. This also brings us back to an important prerequisite for what chains can be supported by this protocol - if both chains post state roots (or a derivative of their state root) to Ethereum, there’s enough building blocks in place to trustlessly prove state about one chain from the other chain. In our early proof of concepts, we’re using storage proofs to do this.

From the source chain, a successful storage proof should look something like:

1. Query the latest Beacon root exposed to the chain via EIP-4788
1. Prove knowledge of the execution client state root which should be a member of the merkle trie that generated the beacon root
1. Prove an account’s storage root where “account” here is the contract that the destination chain posts its state root on L1
1. Prove the state root’s storage location in that account
1. Prove an account’s storage root where “account” here is the RIP-7755Inbox contract on destination chain
1. Prove the storage slot in RIP-7755Inbox that should represent a receipt of the requested call having been made

Storage Proofs in this capacity are how we’re proving state for early iterations of a proof-of-concept for the protocol. However, they are not necessarily the only way to do this. For this reason, we have abstracted the proof system to be separate from the `RIP7755Inbox` and `RIP7755Outbox` contracts, leaving flexibility for future solutions that may be more efficient or easier to implement / generate.

## License

This project is licensed under the MIT License.
