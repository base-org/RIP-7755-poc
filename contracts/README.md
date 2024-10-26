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

## Currently Deployed Contracts for Testing

#### Arbitrum Sepolia MockVerifier:

```txt
Deployer: 0x8C1a617BdB47342F9C17Ac8750E0b070c372C721
Deployed to: 0x49E2cDC9e81825B6C718ae8244fe0D5b062F4874
Transaction hash: 0x134599df38b0f3a23791a0a25720147add001332c81e52fdb0ffb428619a249b
```

request hash used for test proof generation:
0xd758704a57f68d8454a2e178564de8917b3f5403c103f296ec973c5c0844850c

#### Optimism Sepolia MockVerifier:

```txt
Deployer: 0x8C1a617BdB47342F9C17Ac8750E0b070c372C721
Deployed to: 0x49E2cDC9e81825B6C718ae8244fe0D5b062F4874
Transaction hash: 0x7067bff4047efd8559350008c1b3d233e5539885da7467881349bcc66fb9abba
```

request hash used for test proof generation:
0xe38ad8c9e84178325f28799eb3aaae72551b2eea7920c43d88854edd350719f5
