import type { Address } from "viem";
import { SupportedChains } from "./common/types/chain";

export default {
  sourceChain: SupportedChains.BaseSepolia,
  // dstChain: SupportedChains.OptimismSepolia,
  dstChain: SupportedChains.ArbitrumSepolia,
  // requestHash:
  //   "0xe38ad8c9e84178325f28799eb3aaae72551b2eea7920c43d88854edd350719f5" as Address, // opt-sep
  requestHash:
    "0x2ac60f23d7c0dea48c6b0383f3f3c4453a0983beb90d45cbee51ba52a4b4b0f9" as Address,
};
