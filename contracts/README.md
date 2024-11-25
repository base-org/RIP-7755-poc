# RIP-7755 Contracts

This repo consists of work-in-progress implementations of the smart contracts making up [RIP-7755](https://github.com/ethereum/RIPs/pull/31);

## Getting Started

### Install dependencies

```bash
forge install
```

### Compile contracts

```bash
forge build
```

### Run tests

```bash
make test
```

### Check coverage report

```bash
make coverage
```

## RIP-7755 Contracts

The contracts making up RIP-7755 can be split up into source chain contracts and destination chain contracts.

- **Source Chain**
  - [`RIP7755Outbox`](./src/RIP7755Outbox.sol) - The entrypoint for a user submitting a request for a cross-chain call
  - Provers
    - [`ArbitrumProver`](./src/provers/ArbitrumProver.sol) - Implements a proof system to validate state on Arbitrum. Should be used if sending a call to an Arbitrum chain
    - [`OPStackProver`](./src/provers/OPStackProver.sol) - Implements a proof system to validate state on any OP Stack chain. Should be used if sending a call to an OP Stack chain
- **Destination Chain**
  - [`RIP7755Inbox`](./src/RIP7755Inbox.sol) - The target contract that an off-chain Fulfiller should submit a requested call to. This contract's storage is what needs to be proven in the proofs submitted to one of the prover contracts above
