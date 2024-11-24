import type { Address } from "viem";
import { SupportedChains } from "./common/types/chain";

export default {
  sourceChain: SupportedChains.MockBase,
  dstChain: SupportedChains.MockOptimism,
  l1: SupportedChains.MockL1,
  requestHash:
    "0x58592484f8021232d1b9b938e1bed204956dc7d0b2f393561d5aab54750f3552" as Address,
  devnet: true,
};
