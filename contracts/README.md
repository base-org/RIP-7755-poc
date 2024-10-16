# RIP-7755 Contracts

This repo consists of work-in-progress implementations of the smart contracts making up [RIP-7755](https://github.com/ethereum/RIPs/pull/31);

## Getting Started

Install dependencies

```bash
forge install
```

Compile contracts

```bash
forge build
```

Run tests

```bash
make test
```

Check coverage report

```bash
make coverage
```

## Currently Deployed Contracts for Testing

#### Arbitrum Sepolia MockVerifier:

```txt
Deployer: 0x8C1a617BdB47342F9C17Ac8750E0b070c372C721
Deployed to: 0x49E2cDC9e81825B6C718ae8244fe0D5b062F4874
Transaction hash: 0x134599df38b0f3a23791a0a25720147add001332c81e52fdb0ffb428619a249b
```

request hash used for test proof generation:
0x30afd8ae26fc42a6908eab6bafc617694d2c4a25a93ecafe0df925106f592137

#### Optimism Sepolia MockVerifier:

```txt
Deployer: 0x8C1a617BdB47342F9C17Ac8750E0b070c372C721
Deployed to: 0x49E2cDC9e81825B6C718ae8244fe0D5b062F4874
Transaction hash: 0x7067bff4047efd8559350008c1b3d233e5539885da7467881349bcc66fb9abba
```

request hash used for test proof generation:
0xe38ad8c9e84178325f28799eb3aaae72551b2eea7920c43d88854edd350719f5
