import type { Address } from "viem";

export default function bytes32ToAddress(input: Address): Address {
  return `0x${input.slice(26).toLowerCase()}` as Address;
}
