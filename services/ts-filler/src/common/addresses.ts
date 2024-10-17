import { type Address } from "viem";

import type { SupportedChains } from "../types/chains";

type ChainAddresses = { [key: string]: Address };

export default {
  arbitrumSepolia: {
    rip7755VerifierContractAddr: "0x49E2cDC9e81825B6C718ae8244fe0D5b062F4874",
  },
  optimismSepolia: {
    l2MessagePasserAddr: "0x4200000000000000000000000000000000000016",
    rip7755VerifierContractAddr: "0x49E2cDC9e81825B6C718ae8244fe0D5b062F4874",
    opSepoliaWethAddr: "0xAd6A7addf807D846A590E76C5830B609F831Ba2E",
  },
  sepolia: {
    anchorStateRegistryAddr: "0x218CD9489199F321E1177b56385d333c5B598629",
    arbRollupAddr: "0xd80810638dbDF9081b72C1B33c65375e807281C8",
  },
  baseSepolia: {},
} as Record<SupportedChains, ChainAddresses>;
