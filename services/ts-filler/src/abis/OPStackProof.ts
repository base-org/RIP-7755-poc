export default [
  {
    name: "proof",
    type: "tuple",
    internalType: "struct OPStackProver.RIP7755Proof",
    components: [
      { name: "l2StateRoot", type: "bytes32", internalType: "bytes32" },
      {
        name: "l2MessagePasserStorageRoot",
        type: "bytes32",
        internalType: "bytes32",
      },
      { name: "l2BlockHash", type: "bytes32", internalType: "bytes32" },
      {
        name: "stateProofParams",
        type: "tuple",
        internalType: "struct StateValidator.StateProofParameters",
        components: [
          { name: "beaconRoot", type: "bytes32", internalType: "bytes32" },
          {
            name: "beaconOracleTimestamp",
            type: "uint256",
            internalType: "uint256",
          },
          {
            name: "executionStateRoot",
            type: "bytes32",
            internalType: "bytes32",
          },
          {
            name: "stateRootProof",
            type: "bytes32[]",
            internalType: "bytes32[]",
          },
        ],
      },
      {
        name: "dstL2StateRootProofParams",
        type: "tuple",
        internalType: "struct StateValidator.AccountProofParameters",
        components: [
          { name: "storageKey", type: "bytes", internalType: "bytes" },
          { name: "storageValue", type: "bytes", internalType: "bytes" },
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
      {
        name: "dstL2AccountProofParams",
        type: "tuple",
        internalType: "struct StateValidator.AccountProofParameters",
        components: [
          { name: "storageKey", type: "bytes", internalType: "bytes" },
          { name: "storageValue", type: "bytes", internalType: "bytes" },
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
