# RRC-7755 Contracts

This repo consists of work-in-progress implementations of the smart contracts making up [RRC-7755](https://github.com/ethereum/RIPs/blob/master/RIPS/rip-7755.md);

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

### Run Scripts

Create a `.env` file in this directory with the following:

```txt
ARBITRUM_SEPOLIA_RPC=
OPTIMISM_SEPOLIA_RPC=
BASE_SEPOLIA_RPC=
```

Create a cast wallet with the following command (you'll need a private key ready - if you don't have one, you can create one with `cast wallet new` first):

```bash
cast wallet import testnet-admin --interactive
```

Enter the private key of the account you want to use. Note, this account needs to be funded on all chains you'd like to submit requests to.

There are two types of requests you can submit, standard and ERC-4337 User Operations.

#### Standard Requests

Base Sepolia -> Arbitrum Sepolia

```bash
make submit-base-to-arbitrum
```

Base Sepolia -> Optimism Sepolia

```bash
make submit-base-to-optimism
```

Arbitrum Sepolia -> Base Sepolia

```bash
make submit-arbitrum-to-base
```

Arbitrum Sepolia -> Optimism Sepolia

```bash
make submit-optimism-to-arbitrum
```

Optimism Sepolia -> Base Sepolia

```bash
make submit-optimism-to-base
```

#### ERC-4337 User Operations

Base Sepolia -> Arbitrum Sepolia

```bash
make userop-base-to-arbitrum
```

Base Sepolia -> Optimism Sepolia

```bash
make userop-base-to-optimism
```

Arbitrum Sepolia -> Base Sepolia

```bash
make userop-arbitrum-to-base
```

Arbitrum Sepolia -> Optimism Sepolia

```bash
make userop-arbitrum-to-optimism
```

Optimism Sepolia -> Arbitrum Sepolia

```bash
make userop-optimism-to-arbitrum
```

Optimism Sepolia -> Base Sepolia

```bash
make userop-optimism-to-base
```
