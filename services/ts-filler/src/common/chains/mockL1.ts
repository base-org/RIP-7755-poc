import { defineChain } from "viem";

export const mockL1 = defineChain({
  id: 31337,
  name: "Mock L1",
  nativeCurrency: {
    decimals: 18,
    name: "Ether",
    symbol: "ETH",
  },
  rpcUrls: {
    default: {
      http: ["http://localhost:8545"],
    },
  },
  blockExplorers: {
    default: { name: "Explorer", url: "" },
  },
  contracts: {},
});
