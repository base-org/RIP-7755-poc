import type { Address } from "viem";

import { SupportedChains } from "./types/chains";

export default {
  sourceChain: SupportedChains.BaseSepolia,
  dstChain: SupportedChains.ArbitrumSepolia,
  // requestHash:
  //   "0xe38ad8c9e84178325f28799eb3aaae72551b2eea7920c43d88854edd350719f5" as Address, // opt-sep
  requestHash:
    "0x30afd8ae26fc42a6908eab6bafc617694d2c4a25a93ecafe0df925106f592137" as Address,
};
