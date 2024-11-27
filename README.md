![Base](logo.webp)

# RIP-7755

## Overview

RIP-7755 is a Rollup Improvement Proposal designed to establish a standardized, permissionless, and decentralized protocol for low-level cross-chain calls. By implementing immutable on-chain rules that incentivize off-chain participants, known as “fulfillers” in this context, to compete for transaction fees associated with cross-chain calls, we anticipate a significant enhancement in user experience without compromising on security or decentralization.

When a user initiates a request for a cross-chain call, it is accompanied by a financial incentive for the first actor who can successfully execute the call. This reward is granted to the fulfiller only if they can provide cryptographic proof that the cross-chain call was executed successfully and correctly. One method to achieve this is through the use of storage proofs.

For more information, read the full proposal [here](https://github.com/ethereum/RIPs/blob/master/RIPS/rip-7755.md).

This repository serves as a proof of concept implementation of the RIP-7755 protocol.

## Components

- [Contracts](./contracts/README.md)
- [Frontend](./frontend/README.md)
- [Fulfiller](./services/ts-filler/README.md)

There is a second implementation of a fulfiller written in Go that is currently in progress.

## License

This project is licensed under the MIT License.
