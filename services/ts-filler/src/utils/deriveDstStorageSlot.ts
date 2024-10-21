import { encodeAbiParameters, keccak256, type Address } from "viem";

const opSepoliaWethStorageSlot = 3n;
const usrAddr = "0x7504637e0017a24E699579e7f5BE0d0F4229F1EC" as Address;

export function deriveOpSepoliaWethStorageSlot(): Address {
  return keccak256(
    encodeAbiParameters(
      [{ type: "address" }, { type: "uint256" }],
      [usrAddr, opSepoliaWethStorageSlot]
    )
  );
}
