import { defineChain } from "viem";

export const chainB = defineChain({
  id: 111112,
  name: "Chain B",
  nativeCurrency: {
    decimals: 18,
    name: "Ether",
    symbol: "ETH",
  },
  rpcUrls: {
    default: {
      http: ["http://localhost:8547"],
    },
  },
  blockExplorers: {
    default: { name: "Explorer", url: "" },
  },
  contracts: {},
});
