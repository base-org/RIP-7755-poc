import type { Address } from "viem";
import { SupportedChains } from "./common/types/chain";

export default {
  sourceChain: SupportedChains.BaseSepolia,
  dstChain: SupportedChains.ArbitrumSepolia,
  l1: SupportedChains.Sepolia,
  requestHash:
    "0x58592484f8021232d1b9b938e1bed204956dc7d0b2f393561d5aab54750f3552" as Address,
  devnet: false,
  magicSpendThreshold: 0.001,
  gasSponsorThreshold: 0.0005,
};
