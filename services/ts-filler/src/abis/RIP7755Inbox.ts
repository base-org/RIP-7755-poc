export default [
  {
    type: "function",
    name: "executeMessage",
    inputs: [
      { name: "sourceChain", type: "string", internalType: "string" },
      { name: "sender", type: "string", internalType: "string" },
      { name: "payload", type: "bytes", internalType: "bytes" },
      { name: "attributes", type: "bytes[]", internalType: "bytes[]" },
    ],
    outputs: [{ name: "", type: "bytes4", internalType: "bytes4" }],
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
          {
            name: "fulfiller",
            type: "address",
            internalType: "address",
          },
        ],
      },
    ],
    stateMutability: "view",
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
  {
    type: "error",
    name: "AttributeNotFound",
    inputs: [{ name: "selector", type: "bytes4", internalType: "bytes4" }],
  },
  { type: "error", name: "CallAlreadyFulfilled", inputs: [] },
  { type: "error", name: "FailedInnerCall", inputs: [] },
  {
    type: "error",
    name: "InvalidValue",
    inputs: [
      { name: "expected", type: "uint256", internalType: "uint256" },
      { name: "actual", type: "uint256", internalType: "uint256" },
    ],
  },
  {
    type: "error",
    name: "StringsInsufficientHexLength",
    inputs: [
      { name: "value", type: "uint256", internalType: "uint256" },
      { name: "length", type: "uint256", internalType: "uint256" },
    ],
  },
] as const;
