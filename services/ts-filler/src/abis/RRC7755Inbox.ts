export default [
  {
    type: "constructor",
    inputs: [{ name: "entryPoint", type: "address", internalType: "address" }],
    stateMutability: "nonpayable",
  },
  { type: "receive", stateMutability: "payable" },
  {
    type: "function",
    name: "ENTRY_POINT",
    inputs: [],
    outputs: [
      {
        name: "",
        type: "address",
        internalType: "contract IEntryPoint",
      },
    ],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "entryPointDeposit",
    inputs: [{ name: "amount", type: "uint256", internalType: "uint256" }],
    outputs: [],
    stateMutability: "payable",
  },
  {
    type: "function",
    name: "entryPointWithdrawTo",
    inputs: [
      {
        name: "withdrawAddress",
        type: "address",
        internalType: "address payable",
      },
      { name: "amount", type: "uint256", internalType: "uint256" },
    ],
    outputs: [],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "fulfill",
    inputs: [
      { name: "sourceChain", type: "bytes32", internalType: "bytes32" },
      { name: "sender", type: "bytes32", internalType: "bytes32" },
      { name: "payload", type: "bytes", internalType: "bytes" },
      { name: "attributes", type: "bytes[]", internalType: "bytes[]" },
      { name: "fulfiller", type: "address", internalType: "address" },
    ],
    outputs: [],
    stateMutability: "payable",
  },
  {
    type: "function",
    name: "fulfillerClaimAddress",
    inputs: [{ name: "fulfiller", type: "address", internalType: "address" }],
    outputs: [
      { name: "claimAddress", type: "address", internalType: "address" },
    ],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "getFulfillmentInfo",
    inputs: [{ name: "requestHash", type: "bytes32", internalType: "bytes32" }],
    outputs: [
      {
        name: "",
        type: "tuple",
        internalType: "struct RRC7755Inbox.FulfillmentInfo",
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
    type: "function",
    name: "getGasBalance",
    inputs: [{ name: "account", type: "address", internalType: "address" }],
    outputs: [{ name: "", type: "uint256", internalType: "uint256" }],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "getMagicSpendBalance",
    inputs: [
      { name: "account", type: "address", internalType: "address" },
      { name: "token", type: "address", internalType: "address" },
    ],
    outputs: [{ name: "", type: "uint256", internalType: "uint256" }],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "getRequestId",
    inputs: [
      { name: "sourceChain", type: "bytes32", internalType: "bytes32" },
      { name: "sender", type: "bytes32", internalType: "bytes32" },
      {
        name: "destinationChain",
        type: "bytes32",
        internalType: "bytes32",
      },
      { name: "receiver", type: "bytes32", internalType: "bytes32" },
      { name: "payload", type: "bytes", internalType: "bytes" },
      { name: "attributes", type: "bytes[]", internalType: "bytes[]" },
    ],
    outputs: [{ name: "", type: "bytes32", internalType: "bytes32" }],
    stateMutability: "pure",
  },
  {
    type: "function",
    name: "magicSpendDeposit",
    inputs: [
      { name: "token", type: "address", internalType: "address" },
      { name: "amount", type: "uint256", internalType: "uint256" },
    ],
    outputs: [],
    stateMutability: "payable",
  },
  {
    type: "function",
    name: "postOp",
    inputs: [
      {
        name: "mode",
        type: "uint8",
        internalType: "enum IPaymaster.PostOpMode",
      },
      { name: "context", type: "bytes", internalType: "bytes" },
      { name: "", type: "uint256", internalType: "uint256" },
      { name: "", type: "uint256", internalType: "uint256" },
    ],
    outputs: [],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "setClaimAddress",
    inputs: [
      {
        name: "fulfillerClaimAddr",
        type: "address",
        internalType: "address",
      },
    ],
    outputs: [],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "totalTrackedGasBalance",
    inputs: [],
    outputs: [{ name: "", type: "uint256", internalType: "uint256" }],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "validatePaymasterUserOp",
    inputs: [
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
      { name: "userOpHash", type: "bytes32", internalType: "bytes32" },
      { name: "maxCost", type: "uint256", internalType: "uint256" },
    ],
    outputs: [
      { name: "context", type: "bytes", internalType: "bytes" },
      {
        name: "validationData",
        type: "uint256",
        internalType: "uint256",
      },
    ],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "withdrawGasExcess",
    inputs: [{ name: "token", type: "address", internalType: "address" }],
    outputs: [],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "withdrawTo",
    inputs: [
      { name: "token", type: "address", internalType: "address" },
      {
        name: "withdrawAddress",
        type: "address",
        internalType: "address",
      },
      { name: "amount", type: "uint256", internalType: "uint256" },
    ],
    outputs: [],
    stateMutability: "nonpayable",
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
    type: "event",
    name: "ClaimAddressSet",
    inputs: [
      {
        name: "fulfiller",
        type: "address",
        indexed: true,
        internalType: "address",
      },
      {
        name: "claimAddress",
        type: "address",
        indexed: true,
        internalType: "address",
      },
    ],
    anonymous: false,
  },
  {
    type: "event",
    name: "GasWithdrawal",
    inputs: [
      {
        name: "caller",
        type: "address",
        indexed: true,
        internalType: "address",
      },
      {
        name: "withdrawAddress",
        type: "address",
        indexed: true,
        internalType: "address",
      },
      {
        name: "amount",
        type: "uint256",
        indexed: false,
        internalType: "uint256",
      },
    ],
    anonymous: false,
  },
  {
    type: "event",
    name: "MagicSpendWithdrawal",
    inputs: [
      {
        name: "caller",
        type: "address",
        indexed: true,
        internalType: "address",
      },
      {
        name: "withdrawAddress",
        type: "address",
        indexed: true,
        internalType: "address",
      },
      {
        name: "amount",
        type: "uint256",
        indexed: false,
        internalType: "uint256",
      },
    ],
    anonymous: false,
  },
  {
    type: "error",
    name: "AttributeNotFound",
    inputs: [{ name: "selector", type: "bytes4", internalType: "bytes4" }],
  },
  { type: "error", name: "CallAlreadyFulfilled", inputs: [] },
  {
    type: "error",
    name: "InsufficientGasBalance",
    inputs: [
      { name: "account", type: "address", internalType: "address" },
      { name: "balance", type: "uint256", internalType: "uint256" },
      { name: "amount", type: "uint256", internalType: "uint256" },
    ],
  },
  {
    type: "error",
    name: "InsufficientMagicSpendBalance",
    inputs: [
      { name: "account", type: "address", internalType: "address" },
      { name: "balance", type: "uint256", internalType: "uint256" },
      { name: "amount", type: "uint256", internalType: "uint256" },
    ],
  },
  {
    type: "error",
    name: "InvalidValue",
    inputs: [
      { name: "expected", type: "uint256", internalType: "uint256" },
      { name: "actual", type: "uint256", internalType: "uint256" },
    ],
  },
  { type: "error", name: "NotEntryPoint", inputs: [] },
  { type: "error", name: "UserOp", inputs: [] },
  { type: "error", name: "ZeroAddress", inputs: [] },
  { type: "error", name: "ZeroAmount", inputs: [] },
] as const;
