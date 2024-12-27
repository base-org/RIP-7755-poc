export default [
  {
    type: "function",
    name: "getThresholdHash",
    inputs: [
      { name: "domain", type: "uint256", internalType: "uint256" },
      { name: "id", type: "uint256", internalType: "uint256" },
    ],
    outputs: [{ name: "", type: "bytes32", internalType: "bytes32" }],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "setHash",
    inputs: [
      { name: "domain", type: "uint256", internalType: "uint256" },
      { name: "id", type: "uint256", internalType: "uint256" },
      { name: "hash", type: "bytes32", internalType: "bytes32" },
    ],
    outputs: [],
    stateMutability: "nonpayable",
  },
] as const;
