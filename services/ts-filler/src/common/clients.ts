import { createPublicClient, http } from "viem";
import {
  baseSepolia,
  sepolia,
  optimismSepolia,
  arbitrumSepolia,
} from "viem/chains";

import type { SupportedChains } from "../types/chains";

export default {
  arbitrumSepolia: createPublicClient({
    chain: arbitrumSepolia,
    transport: http(process.env.ARBITRUM_SEPOLIA_RPC),
  }),
  baseSepolia: createPublicClient({
    chain: baseSepolia,
    transport: http(),
  }),
  optimismSepolia: createPublicClient({
    chain: optimismSepolia,
    transport: http(),
  }),
  sepolia: createPublicClient({
    chain: sepolia,
    transport: http(process.env.SEPOLIA_RPC),
  }),
} as Record<SupportedChains, any>;
