import { decodeAbiParameters, type Hex } from "viem";

import Attributes from "./attributes";
import PaymasterData from "../../abis/PaymasterData";

export default function extractAttributesFromUserOp(op: any): Attributes {
  const paymasterData = `0x${op.paymasterAndData.slice(106)}` as Hex;
  const [, , , attributes] = decodeAbiParameters(PaymasterData, paymasterData);
  return new Attributes(attributes as Hex[]);
}
