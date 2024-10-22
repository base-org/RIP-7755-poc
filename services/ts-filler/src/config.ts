import type { Address } from "viem";
import { SupportedChains } from "./common/types/chain";

export default {
  sourceChain: SupportedChains.BaseSepolia,
  // dstChain: SupportedChains.OptimismSepolia,
  dstChain: SupportedChains.ArbitrumSepolia,
  // requestHash:
  //   "0xe38ad8c9e84178325f28799eb3aaae72551b2eea7920c43d88854edd350719f5" as Address, // opt-sep
  requestHash:
    "0xd758704a57f68d8454a2e178564de8917b3f5403c103f296ec973c5c0844850c" as Address,
};
