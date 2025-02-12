export default [
  {
    name: "userOp",
    type: "tuple",
    internalType: "struct PackedUserOperation",
    components: [
      { name: "sender", type: "address", internalType: "address" },
      { name: "nonce", type: "uint256", internalType: "uint256" },
      { name: "initCode", type: "bytes", internalType: "bytes" },
      { name: "callData", type: "bytes", internalType: "bytes" },
      {
        name: "accountGasLimits",
        type: "bytes32",
        internalType: "bytes32",
      },
      {
        name: "preVerificationGas",
        type: "uint256",
        internalType: "uint256",
      },
      { name: "gasFees", type: "bytes32", internalType: "bytes32" },
      {
        name: "paymasterAndData",
        type: "bytes",
        internalType: "bytes",
      },
      { name: "signature", type: "bytes", internalType: "bytes" },
    ],
  },
] as const;
