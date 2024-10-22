import { type Address } from "viem";

export default {
  slots: {
    anchorStateRegistrySlot:
      "0xa6eef7e35abe7026729641147f7915573c7e97b47efa546f5f6e3230263bcb49",
    fulfillmentInfoSlot:
      "0x43f1016e17bdb0194ec37b77cf476d255de00011d02616ab831d2e2ce63d9ee2",
  },
} as { slots: Record<string, Address> };
