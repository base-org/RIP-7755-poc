import { defineChain } from "viem";

export const chainA = defineChain({
  id: 111111,
  name: "Chain A",
  nativeCurrency: {
    decimals: 18,
    name: "Ether",
    symbol: "ETH",
  },
  rpcUrls: {
    default: {
      http: ["http://localhost:8546"],
    },
  },
  blockExplorers: {
    default: { name: "Explorer", url: "" },
  },
  contracts: {},
});
