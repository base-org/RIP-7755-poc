export default [
  {
    name: "calls",
    type: "tuple[]",
    internalType: "struct Call[]",
    components: [
      { name: "to", type: "bytes32", internalType: "bytes32" },
      { name: "data", type: "bytes", internalType: "bytes" },
      { name: "value", type: "uint256", internalType: "uint256" },
    ],
  },
] as const;
