import type { Address } from "viem";

export type CallType = {
  to: Address;
  data: Address;
  value: bigint;
};
