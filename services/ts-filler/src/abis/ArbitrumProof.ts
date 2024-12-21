export default [
  {
    name: "proof",
    type: "tuple",
    internalType: "struct ArbitrumProver.RIP7755Proof",
    components: [
      {
        name: "encodedBlockArray",
        type: "bytes",
        internalType: "bytes",
      },
      {
        name: "afterState",
        type: "tuple",
        internalType: "struct ArbitrumProver.AssertionState",
        components: [
          {
            name: "globalState",
            type: "tuple",
            internalType: "struct ArbitrumProver.GlobalState",
            components: [
              {
                name: "bytes32Vals",
                type: "bytes32[2]",
                internalType: "bytes32[2]",
              },
              {
                name: "u64Vals",
                type: "uint64[2]",
                internalType: "uint64[2]",
              },
            ],
          },
          {
            name: "machineStatus",
            type: "ArbitrumProver.MachineStatus",
            internalType: "enum ArbitrumProver.MachineStatus",
          },
          {
            name: "endHistoryRoot",
            type: "bytes32",
            internalType: "bytes32",
          },
        ],
      },
      {
        name: "prevAssertionHash",
        type: "bytes32",
        internalType: "bytes32",
      },
      {
        name: "sequencerBatchAcc",
        type: "bytes32",
        internalType: "bytes32",
      },
      {
        name: "stateProofParams",
        type: "tuple",
        internalType: "struct StateValidator.StateProofParameters",
        components: [
          {
            name: "beaconRoot",
            type: "bytes32",
            internalType: "bytes32",
          },
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
      {
        name: "dstL2AccountProofParams",
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
