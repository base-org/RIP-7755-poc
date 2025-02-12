export default [
  { name: "ethAddress", type: "address", internalType: "address" },
  { name: "ethAmount", type: "uint256", internalType: "uint256" },
  { name: "precheck", type: "address", internalType: "address" },
  { name: "attributes", type: "bytes[]", internalType: "bytes[]" },
] as const;
