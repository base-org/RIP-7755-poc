import {
  arbitrumSepolia,
  baseSepolia,
  optimismSepolia,
  sepolia,
} from "viem/chains";
import { createPublicClient, http } from "viem";

import type { ChainConfig } from "../types/chain";

export default {
  // Arbitrum Sepolia
  421614: {
    chainId: 421614,
    proverContracts: {},
    rpcUrl:
      process.env.ARBITRUM_SEPOLIA_RPC ||
      arbitrumSepolia.rpcUrls.default.http[0],
    outboxContract: "0x",
    inboxContract: "0x49E2cDC9e81825B6C718ae8244fe0D5b062F4874",
    l2Oracle: "0xd80810638dbDF9081b72C1B33c65375e807281C8",
    l2OracleStorageKey:
      "0x0000000000000000000000000000000000000000000000000000000000000076",
    contracts: {
      rip7755VerifierContractAddr: "0x49E2cDC9e81825B6C718ae8244fe0D5b062F4874",
    },
    publicClient: createPublicClient({
      chain: arbitrumSepolia,
      transport: http(process.env.ARBITRUM_SEPOLIA_RPC),
    }),
  },
  // Base Sepolia
  84532: {
    chainId: 84532,
    proverContracts: {},
    rpcUrl: process.env.BASE_SEPOLIA_RPC || baseSepolia.rpcUrls.default.http[0],
    outboxContract: "0x",
    inboxContract: "0x",
    l2Oracle: "0x218CD9489199F321E1177b56385d333c5B598629",
    l2OracleStorageKey:
      "0xa6eef7e35abe7026729641147f7915573c7e97b47efa546f5f6e3230263bcb49",
    contracts: {},
    publicClient: createPublicClient({
      chain: baseSepolia,
      transport: http(),
    }),
  },
  // Optimism Sepolia
  11155420: {
    chainId: 11155420,
    proverContracts: {},
    rpcUrl:
      process.env.OPTIMISM_SEPOLIA_RPC ||
      optimismSepolia.rpcUrls.default.http[0],
    outboxContract: "0x",
    inboxContract: "0x49E2cDC9e81825B6C718ae8244fe0D5b062F4874",
    l2Oracle: "0x218CD9489199F321E1177b56385d333c5B598629",
    l2OracleStorageKey:
      "0xa6eef7e35abe7026729641147f7915573c7e97b47efa546f5f6e3230263bcb49",
    contracts: {
      l2MessagePasserAddr: "0x4200000000000000000000000000000000000016",
      rip7755VerifierContractAddr: "0x49E2cDC9e81825B6C718ae8244fe0D5b062F4874",
      opSepoliaWethAddr: "0xAd6A7addf807D846A590E76C5830B609F831Ba2E",
    },
    publicClient: createPublicClient({
      chain: optimismSepolia,
      transport: http(),
    }),
  },
  // Sepolia
  11155111: {
    chainId: 11155111,
    proverContracts: {},
    rpcUrl: process.env.SEPOLIA_RPC || sepolia.rpcUrls.default.http[0],
    outboxContract: "0x",
    inboxContract: "0x",
    l2Oracle: "0x",
    l2OracleStorageKey: "0x",
    contracts: {
      anchorStateRegistryAddr: "0x218CD9489199F321E1177b56385d333c5B598629",
      arbRollupAddr: "0xd80810638dbDF9081b72C1B33c65375e807281C8",
    },
    publicClient: createPublicClient({
      chain: sepolia,
      transport: http(process.env.SEPOLIA_RPC),
    }),
  },
} as Record<number, ChainConfig>;
