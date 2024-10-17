import { arbitrumSepolia, optimismSepolia } from "viem/chains";

import type { ChainConfig } from "../types/chain";

export default {
  // Arbitrum Sepolia
  421614: {
    proverContracts: {},
    rpcUrl:
      process.env.ARBITRUM_SEPOLIA_RPC ||
      arbitrumSepolia.rpcUrls.default.http[0],
    outboxContract: "0x",
    inboxContract: "0x49E2cDC9e81825B6C718ae8244fe0D5b062F4874",
    l2Oracle: "0xd80810638dbDF9081b72C1B33c65375e807281C8",
    l2OracleStorageKey:
      "0x0000000000000000000000000000000000000000000000000000000000000076",
  },
  // Optimism Sepolia
  11155420: {
    proverContracts: {},
    rpcUrl:
      process.env.OPTIMISM_SEPOLIA_RPC ||
      optimismSepolia.rpcUrls.default.http[0],
    outboxContract: "0x",
    inboxContract: "0x49E2cDC9e81825B6C718ae8244fe0D5b062F4874",
    l2Oracle: "0x218CD9489199F321E1177b56385d333c5B598629",
    l2OracleStorageKey:
      "0xa6eef7e35abe7026729641147f7915573c7e97b47efa546f5f6e3230263bcb49",
  },
} as Record<number, ChainConfig>;
