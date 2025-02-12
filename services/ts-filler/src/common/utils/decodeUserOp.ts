import { decodeAbiParameters, type Hex } from "viem";

import PackedUserOperation from "../../abis/PackedUserOperation";

export default function decodeUserOp(payload: Hex): any {
  const [op] = decodeAbiParameters(PackedUserOperation, payload);
  return op;
}
