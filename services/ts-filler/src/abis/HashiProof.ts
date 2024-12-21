export default [
  {
    name: "proof",
    type: "tuple",
    internalType: "struct HashiProver.RIP7755Proof",
    components: [
      {
        name: "rlpEncodedBlockHeader",
        type: "bytes",
        internalType: "bytes",
      },
      {
        name: "dstAccountProofParams",
        type: "tuple",
        internalType: "struct StateValidator.AccountProofParameters",
        components: [
          {
            name: "storageKey",
            type: "bytes",
            internalType: "bytes",
          },
          {
            name: "storageValue",
            type: "bytes",
            internalType: "bytes",
          },
          {
            name: "accountProof",
            type: "bytes[]",
            internalType: "bytes[]",
          },
          {
            name: "storageProof",
            type: "bytes[]",
            internalType: "bytes[]",
          },
        ],
      },
    ],
  },
] as const;
