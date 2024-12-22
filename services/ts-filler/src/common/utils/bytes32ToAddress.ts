import type { Address, Hex } from "viem";

export default function bytes32ToAddress(input: Hex): Address {
  return `0x${input.slice(26).toLowerCase()}` as Address;
}
