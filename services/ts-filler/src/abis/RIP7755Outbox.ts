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
    name: "cancelMessage",
    inputs: [
      { name: "sender", type: "string", internalType: "string" },
      { name: "receiver", type: "string", internalType: "string" },
      { name: "payload", type: "bytes", internalType: "bytes" },
      {
        name: "expandedAttributes",
        type: "bytes[]",
        internalType: "bytes[]",
      },
    ],
    outputs: [],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "claimReward",
    inputs: [
      { name: "sender", type: "string", internalType: "string" },
      { name: "receiver", type: "string", internalType: "string" },
      { name: "payload", type: "bytes", internalType: "bytes" },
      {
        name: "expandedAttributes",
        type: "bytes[]",
        internalType: "bytes[]",
      },
      { name: "proof", type: "bytes", internalType: "bytes" },
      { name: "payTo", type: "address", internalType: "address" },
    ],
    outputs: [],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "getMessageStatus",
    inputs: [{ name: "messageId", type: "bytes32", internalType: "bytes32" }],
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
    name: "sendMessage",
    inputs: [
      {
        name: "destinationChain",
        type: "string",
        internalType: "string",
      },
      { name: "receiver", type: "string", internalType: "string" },
      { name: "payload", type: "bytes", internalType: "bytes" },
      { name: "attributes", type: "bytes[]", internalType: "bytes[]" },
    ],
    outputs: [{ name: "", type: "bytes32", internalType: "bytes32" }],
    stateMutability: "payable",
  },
  {
    type: "function",
    name: "supportsAttribute",
    inputs: [{ name: "selector", type: "bytes4", internalType: "bytes4" }],
    outputs: [{ name: "", type: "bool", internalType: "bool" }],
    stateMutability: "pure",
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
    name: "MessagePosted",
    inputs: [
      {
        name: "outboxId",
        type: "bytes32",
        indexed: true,
        internalType: "bytes32",
      },
      {
        name: "sender",
        type: "string",
        indexed: false,
        internalType: "string",
      },
      {
        name: "receiver",
        type: "string",
        indexed: false,
        internalType: "string",
      },
      {
        name: "payload",
        type: "bytes",
        indexed: false,
        internalType: "bytes",
      },
      {
        name: "value",
        type: "uint256",
        indexed: false,
        internalType: "uint256",
      },
      {
        name: "attributes",
        type: "bytes[]",
        indexed: false,
        internalType: "bytes[]",
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
  { type: "error", name: "ExpiryTooSoon", inputs: [] },
  { type: "error", name: "FailedInnerCall", inputs: [] },
  {
    type: "error",
    name: "InvalidAttributeLength",
    inputs: [
      { name: "expected", type: "uint256", internalType: "uint256" },
      { name: "actual", type: "uint256", internalType: "uint256" },
    ],
  },
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
  {
    type: "error",
    name: "SafeERC20FailedOperation",
    inputs: [{ name: "token", type: "address", internalType: "address" }],
  },
  {
    type: "error",
    name: "StringsInsufficientHexLength",
    inputs: [
      { name: "value", type: "uint256", internalType: "uint256" },
      { name: "length", type: "uint256", internalType: "uint256" },
    ],
  },
  {
    type: "error",
    name: "UnsupportedAttribute",
    inputs: [{ name: "selector", type: "bytes4", internalType: "bytes4" }],
  },
] as const;
