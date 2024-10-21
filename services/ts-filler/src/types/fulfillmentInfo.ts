import type { Address } from "viem";

export type FulfillmentInfoType = {
  timestamp: bigint;
  filler: Address;
};
