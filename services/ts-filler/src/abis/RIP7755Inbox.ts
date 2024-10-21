export default [
  {
    type: "function",
    name: "fulfill",
    inputs: [
      {
        name: "request",
        type: "tuple",
        internalType: "struct CrossChainRequest",
        components: [
          {
            name: "requester",
            type: "address",
            internalType: "address",
          },
          {
            name: "calls",
            type: "tuple[]",
            internalType: "struct Call[]",
            components: [
              { name: "to", type: "address", internalType: "address" },
              { name: "data", type: "bytes", internalType: "bytes" },
              {
                name: "value",
                type: "uint256",
                internalType: "uint256",
              },
            ],
          },
          {
            name: "proverContract",
            type: "address",
            internalType: "address",
          },
          {
            name: "destinationChainId",
            type: "uint256",
            internalType: "uint256",
          },
          {
            name: "inboxContract",
            type: "address",
            internalType: "address",
          },
          {
            name: "l2Oracle",
            type: "address",
            internalType: "address",
          },
          {
            name: "l2OracleStorageKey",
            type: "bytes32",
            internalType: "bytes32",
          },
          {
            name: "rewardAsset",
            type: "address",
            internalType: "address",
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
            name: "precheckContract",
            type: "address",
            internalType: "address",
          },
          { name: "precheckData", type: "bytes", internalType: "bytes" },
        ],
      },
      { name: "fulfiller", type: "address", internalType: "address" },
    ],
    outputs: [],
    stateMutability: "payable",
  },
  {
    type: "function",
    name: "getFulfillmentInfo",
    inputs: [{ name: "requestHash", type: "bytes32", internalType: "bytes32" }],
    outputs: [
      {
        name: "",
        type: "tuple",
        internalType: "struct RIP7755Inbox.FulfillmentInfo",
        components: [
          { name: "timestamp", type: "uint96", internalType: "uint96" },
          { name: "filler", type: "address", internalType: "address" },
        ],
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
            type: "address",
            internalType: "address",
          },
          {
            name: "calls",
            type: "tuple[]",
            internalType: "struct Call[]",
            components: [
              { name: "to", type: "address", internalType: "address" },
              { name: "data", type: "bytes", internalType: "bytes" },
              {
                name: "value",
                type: "uint256",
                internalType: "uint256",
              },
            ],
          },
          {
            name: "proverContract",
            type: "address",
            internalType: "address",
          },
          {
            name: "destinationChainId",
            type: "uint256",
            internalType: "uint256",
          },
          {
            name: "inboxContract",
            type: "address",
            internalType: "address",
          },
          {
            name: "l2Oracle",
            type: "address",
            internalType: "address",
          },
          {
            name: "l2OracleStorageKey",
            type: "bytes32",
            internalType: "bytes32",
          },
          {
            name: "rewardAsset",
            type: "address",
            internalType: "address",
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
            name: "precheckContract",
            type: "address",
            internalType: "address",
          },
          { name: "precheckData", type: "bytes", internalType: "bytes" },
        ],
      },
    ],
    outputs: [{ name: "", type: "bytes32", internalType: "bytes32" }],
    stateMutability: "pure",
  },
  {
    type: "event",
    name: "CallFulfilled",
    inputs: [
      {
        name: "requestHash",
        type: "bytes32",
        indexed: true,
        internalType: "bytes32",
      },
      {
        name: "fulfilledBy",
        type: "address",
        indexed: true,
        internalType: "address",
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
  { type: "error", name: "CallAlreadyFulfilled", inputs: [] },
  { type: "error", name: "FailedInnerCall", inputs: [] },
  { type: "error", name: "InvalidChainId", inputs: [] },
  { type: "error", name: "InvalidInboxContract", inputs: [] },
] as const;
