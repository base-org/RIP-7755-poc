export default [
  {
    type: "function",
    name: "CANCEL_DELAY_SECONDS",
    inputs: [],
    outputs: [{ name: "", type: "uint256", internalType: "uint256" }],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "cancelRequest",
    inputs: [
      {
        name: "request",
        type: "tuple",
        internalType: "struct CrossChainRequest",
        components: [
          {
            name: "requester",
            type: "bytes32",
            internalType: "bytes32",
          },
          {
            name: "calls",
            type: "tuple[]",
            internalType: "struct Call[]",
            components: [
              { name: "to", type: "bytes32", internalType: "bytes32" },
              { name: "data", type: "bytes", internalType: "bytes" },
              {
                name: "value",
                type: "uint256",
                internalType: "uint256",
              },
            ],
          },
          {
            name: "sourceChainId",
            type: "uint256",
            internalType: "uint256",
          },
          { name: "origin", type: "bytes32", internalType: "bytes32" },
          {
            name: "destinationChainId",
            type: "uint256",
            internalType: "uint256",
          },
          {
            name: "inboxContract",
            type: "bytes32",
            internalType: "bytes32",
          },
          {
            name: "l2Oracle",
            type: "bytes32",
            internalType: "bytes32",
          },
          {
            name: "rewardAsset",
            type: "bytes32",
            internalType: "bytes32",
          },
          {
            name: "rewardAmount",
            type: "uint256",
            internalType: "uint256",
          },
          {
            name: "finalityDelaySeconds",
            type: "uint256",
            internalType: "uint256",
          },
          { name: "nonce", type: "uint256", internalType: "uint256" },
          { name: "expiry", type: "uint256", internalType: "uint256" },
          {
            name: "extraData",
            type: "bytes[]",
            internalType: "bytes[]",
          },
        ],
      },
    ],
    outputs: [],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "claimReward",
    inputs: [
      {
        name: "request",
        type: "tuple",
        internalType: "struct CrossChainRequest",
        components: [
          {
            name: "requester",
            type: "bytes32",
            internalType: "bytes32",
          },
          {
            name: "calls",
            type: "tuple[]",
            internalType: "struct Call[]",
            components: [
              { name: "to", type: "bytes32", internalType: "bytes32" },
              { name: "data", type: "bytes", internalType: "bytes" },
              {
                name: "value",
                type: "uint256",
                internalType: "uint256",
              },
            ],
          },
          {
            name: "sourceChainId",
            type: "uint256",
            internalType: "uint256",
          },
          { name: "origin", type: "bytes32", internalType: "bytes32" },
          {
            name: "destinationChainId",
            type: "uint256",
            internalType: "uint256",
          },
          {
            name: "inboxContract",
            type: "bytes32",
            internalType: "bytes32",
          },
          {
            name: "l2Oracle",
            type: "bytes32",
            internalType: "bytes32",
          },
          {
            name: "rewardAsset",
            type: "bytes32",
            internalType: "bytes32",
          },
          {
            name: "rewardAmount",
            type: "uint256",
            internalType: "uint256",
          },
          {
            name: "finalityDelaySeconds",
            type: "uint256",
            internalType: "uint256",
          },
          { name: "nonce", type: "uint256", internalType: "uint256" },
          { name: "expiry", type: "uint256", internalType: "uint256" },
          {
            name: "extraData",
            type: "bytes[]",
            internalType: "bytes[]",
          },
        ],
      },
      { name: "proof", type: "bytes", internalType: "bytes" },
      { name: "payTo", type: "address", internalType: "address" },
    ],
    outputs: [],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "getRequestStatus",
    inputs: [{ name: "requestHash", type: "bytes32", internalType: "bytes32" }],
    outputs: [
      {
        name: "",
        type: "uint8",
        internalType: "enum RIP7755Outbox.CrossChainCallStatus",
      },
    ],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "hashRequest",
    inputs: [
      {
        name: "request",
        type: "tuple",
        internalType: "struct CrossChainRequest",
        components: [
          {
            name: "requester",
            type: "bytes32",
            internalType: "bytes32",
          },
          {
            name: "calls",
            type: "tuple[]",
            internalType: "struct Call[]",
            components: [
              { name: "to", type: "bytes32", internalType: "bytes32" },
              { name: "data", type: "bytes", internalType: "bytes" },
              {
                name: "value",
                type: "uint256",
                internalType: "uint256",
              },
            ],
          },
          {
            name: "sourceChainId",
            type: "uint256",
            internalType: "uint256",
          },
          { name: "origin", type: "bytes32", internalType: "bytes32" },
          {
            name: "destinationChainId",
            type: "uint256",
            internalType: "uint256",
          },
          {
            name: "inboxContract",
            type: "bytes32",
            internalType: "bytes32",
          },
          {
            name: "l2Oracle",
            type: "bytes32",
            internalType: "bytes32",
          },
          {
            name: "rewardAsset",
            type: "bytes32",
            internalType: "bytes32",
          },
          {
            name: "rewardAmount",
            type: "uint256",
            internalType: "uint256",
          },
          {
            name: "finalityDelaySeconds",
            type: "uint256",
            internalType: "uint256",
          },
          { name: "nonce", type: "uint256", internalType: "uint256" },
          { name: "expiry", type: "uint256", internalType: "uint256" },
          {
            name: "extraData",
            type: "bytes[]",
            internalType: "bytes[]",
          },
        ],
      },
    ],
    outputs: [{ name: "", type: "bytes32", internalType: "bytes32" }],
    stateMutability: "pure",
  },
  {
    type: "function",
    name: "hashRequestMemory",
    inputs: [
      {
        name: "request",
        type: "tuple",
        internalType: "struct CrossChainRequest",
        components: [
          {
            name: "requester",
            type: "bytes32",
            internalType: "bytes32",
          },
          {
            name: "calls",
            type: "tuple[]",
            internalType: "struct Call[]",
            components: [
              { name: "to", type: "bytes32", internalType: "bytes32" },
              { name: "data", type: "bytes", internalType: "bytes" },
              {
                name: "value",
                type: "uint256",
                internalType: "uint256",
              },
            ],
          },
          {
            name: "sourceChainId",
            type: "uint256",
            internalType: "uint256",
          },
          { name: "origin", type: "bytes32", internalType: "bytes32" },
          {
            name: "destinationChainId",
            type: "uint256",
            internalType: "uint256",
          },
          {
            name: "inboxContract",
            type: "bytes32",
            internalType: "bytes32",
          },
          {
            name: "l2Oracle",
            type: "bytes32",
            internalType: "bytes32",
          },
          {
            name: "rewardAsset",
            type: "bytes32",
            internalType: "bytes32",
          },
          {
            name: "rewardAmount",
            type: "uint256",
            internalType: "uint256",
          },
          {
            name: "finalityDelaySeconds",
            type: "uint256",
            internalType: "uint256",
          },
          { name: "nonce", type: "uint256", internalType: "uint256" },
          { name: "expiry", type: "uint256", internalType: "uint256" },
          {
            name: "extraData",
            type: "bytes[]",
            internalType: "bytes[]",
          },
        ],
      },
    ],
    outputs: [{ name: "", type: "bytes32", internalType: "bytes32" }],
    stateMutability: "pure",
  },
  {
    type: "function",
    name: "requestCrossChainCall",
    inputs: [
      {
        name: "request",
        type: "tuple",
        internalType: "struct CrossChainRequest",
        components: [
          {
            name: "requester",
            type: "bytes32",
            internalType: "bytes32",
          },
          {
            name: "calls",
            type: "tuple[]",
            internalType: "struct Call[]",
            components: [
              { name: "to", type: "bytes32", internalType: "bytes32" },
              { name: "data", type: "bytes", internalType: "bytes" },
              {
                name: "value",
                type: "uint256",
                internalType: "uint256",
              },
            ],
          },
          {
            name: "sourceChainId",
            type: "uint256",
            internalType: "uint256",
          },
          { name: "origin", type: "bytes32", internalType: "bytes32" },
          {
            name: "destinationChainId",
            type: "uint256",
            internalType: "uint256",
          },
          {
            name: "inboxContract",
            type: "bytes32",
            internalType: "bytes32",
          },
          {
            name: "l2Oracle",
            type: "bytes32",
            internalType: "bytes32",
          },
          {
            name: "rewardAsset",
            type: "bytes32",
            internalType: "bytes32",
          },
          {
            name: "rewardAmount",
            type: "uint256",
            internalType: "uint256",
          },
          {
            name: "finalityDelaySeconds",
            type: "uint256",
            internalType: "uint256",
          },
          { name: "nonce", type: "uint256", internalType: "uint256" },
          { name: "expiry", type: "uint256", internalType: "uint256" },
          {
            name: "extraData",
            type: "bytes[]",
            internalType: "bytes[]",
          },
        ],
      },
    ],
    outputs: [],
    stateMutability: "payable",
  },
  {
    type: "event",
    name: "CrossChainCallCanceled",
    inputs: [
      {
        name: "requestHash",
        type: "bytes32",
        indexed: true,
        internalType: "bytes32",
      },
    ],
    anonymous: false,
  },
  {
    type: "event",
    name: "CrossChainCallCompleted",
    inputs: [
      {
        name: "requestHash",
        type: "bytes32",
        indexed: true,
        internalType: "bytes32",
      },
      {
        name: "submitter",
        type: "address",
        indexed: false,
        internalType: "address",
      },
    ],
    anonymous: false,
  },
  {
    type: "event",
    name: "CrossChainCallRequested",
    inputs: [
      {
        name: "requestHash",
        type: "bytes32",
        indexed: true,
        internalType: "bytes32",
      },
      {
        name: "request",
        type: "tuple",
        indexed: false,
        internalType: "struct CrossChainRequest",
        components: [
          {
            name: "requester",
            type: "bytes32",
            internalType: "bytes32",
          },
          {
            name: "calls",
            type: "tuple[]",
            internalType: "struct Call[]",
            components: [
              { name: "to", type: "bytes32", internalType: "bytes32" },
              { name: "data", type: "bytes", internalType: "bytes" },
              {
                name: "value",
                type: "uint256",
                internalType: "uint256",
              },
            ],
          },
          {
            name: "sourceChainId",
            type: "uint256",
            internalType: "uint256",
          },
          { name: "origin", type: "bytes32", internalType: "bytes32" },
          {
            name: "destinationChainId",
            type: "uint256",
            internalType: "uint256",
          },
          {
            name: "inboxContract",
            type: "bytes32",
            internalType: "bytes32",
          },
          {
            name: "l2Oracle",
            type: "bytes32",
            internalType: "bytes32",
          },
          {
            name: "rewardAsset",
            type: "bytes32",
            internalType: "bytes32",
          },
          {
            name: "rewardAmount",
            type: "uint256",
            internalType: "uint256",
          },
          {
            name: "finalityDelaySeconds",
            type: "uint256",
            internalType: "uint256",
          },
          { name: "nonce", type: "uint256", internalType: "uint256" },
          { name: "expiry", type: "uint256", internalType: "uint256" },
          {
            name: "extraData",
            type: "bytes[]",
            internalType: "bytes[]",
          },
        ],
      },
    ],
    anonymous: false,
  },
  {
    type: "error",
    name: "AddressEmptyCode",
    inputs: [{ name: "target", type: "address", internalType: "address" }],
  },
  {
    type: "error",
    name: "AddressInsufficientBalance",
    inputs: [{ name: "account", type: "address", internalType: "address" }],
  },
  {
    type: "error",
    name: "BeaconRootDoesNotMatch",
    inputs: [
      { name: "expected", type: "bytes32", internalType: "bytes32" },
      { name: "actual", type: "bytes32", internalType: "bytes32" },
    ],
  },
  {
    type: "error",
    name: "BeaconRootsOracleCallFailed",
    inputs: [{ name: "callData", type: "bytes", internalType: "bytes" }],
  },
  { type: "error", name: "BytesLengthExceeds32", inputs: [] },
  {
    type: "error",
    name: "CannotCancelRequestBeforeExpiry",
    inputs: [
      {
        name: "currentTimestamp",
        type: "uint256",
        internalType: "uint256",
      },
      { name: "expiry", type: "uint256", internalType: "uint256" },
    ],
  },
  { type: "error", name: "ContentLengthMismatch", inputs: [] },
  { type: "error", name: "EmptyItem", inputs: [] },
  {
    type: "error",
    name: "ExecutionStateRootMerkleProofFailed",
    inputs: [],
  },
  { type: "error", name: "ExpiryTooSoon", inputs: [] },
  { type: "error", name: "FailedInnerCall", inputs: [] },
  { type: "error", name: "FinalityDelaySecondsInProgress", inputs: [] },
  { type: "error", name: "InvalidAccountRLP", inputs: [] },
  { type: "error", name: "InvalidBlockFieldRLP", inputs: [] },
  {
    type: "error",
    name: "InvalidCaller",
    inputs: [
      { name: "caller", type: "address", internalType: "address" },
      {
        name: "expectedCaller",
        type: "address",
        internalType: "address",
      },
    ],
  },
  { type: "error", name: "InvalidDataRemainder", inputs: [] },
  { type: "error", name: "InvalidHeader", inputs: [] },
  { type: "error", name: "InvalidL1Storage", inputs: [] },
  { type: "error", name: "InvalidL2StateRoot", inputs: [] },
  { type: "error", name: "InvalidL2Storage", inputs: [] },
  {
    type: "error",
    name: "InvalidStatus",
    inputs: [
      {
        name: "expected",
        type: "uint8",
        internalType: "enum RIP7755Outbox.CrossChainCallStatus",
      },
      {
        name: "actual",
        type: "uint8",
        internalType: "enum RIP7755Outbox.CrossChainCallStatus",
      },
    ],
  },
  {
    type: "error",
    name: "InvalidValue",
    inputs: [
      { name: "expected", type: "uint256", internalType: "uint256" },
      { name: "received", type: "uint256", internalType: "uint256" },
    ],
  },
  { type: "error", name: "ProofValidationFailed", inputs: [] },
  {
    type: "error",
    name: "SafeERC20FailedOperation",
    inputs: [{ name: "token", type: "address", internalType: "address" }],
  },
  { type: "error", name: "UnexpectedList", inputs: [] },
  { type: "error", name: "UnexpectedString", inputs: [] },
] as const;
