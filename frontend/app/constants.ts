// Global
export const rewardAsset = "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE";
export const ONE_WEEK = 604800;
export const TWO_WEEKS = 604800 * 2;

// Base Sepolia
export const BASE_SEPOLIA_CHAIN_ID = 84532;
export const baseSepoliaProverContractAddress =
  "0x062fBdCfd17A0346D2A9d89FE233bbAdBd1DC14C";
export const baseSepoliaInboxContractAddress =
  "0xB482b292878FDe64691d028A2237B34e91c7c7ea";
export const baseSepoliaL2OracleContractAddress =
  "0x4C8BA32A5DAC2A720bb35CeDB51D6B067D104205";
export const baseSepoliaL2OracleStorageKey =
  "0xa6eef7e35abe7026729641147f7915573c7e97b47efa546f5f6e3230263bcb49";

// Arbitrum Sepolia
export const ARBITRUM_SEPOLIA_CHAIN_ID = 421614;
export const outboxContractAddress =
  "0xBCd5762cF9B07EF5597014c350CE2efB2b0DB2D2";
export const outboxABI = [
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
      {
        name: "fulfillmentInfo",
        type: "tuple",
        internalType: "struct RIP7755Inbox.FulfillmentInfo",
        components: [
          { name: "timestamp", type: "uint96", internalType: "uint96" },
          { name: "filler", type: "address", internalType: "address" },
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
  { type: "error", name: "ProofValidationFailed", inputs: [] },
  {
    type: "error",
    name: "SafeERC20FailedOperation",
    inputs: [{ name: "token", type: "address", internalType: "address" }],
  },
] as const;
