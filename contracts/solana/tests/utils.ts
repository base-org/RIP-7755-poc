import { keccak_256 } from "@noble/hashes/sha3";
import { serialize } from "borsh";

import { CrossChainRequest, Req, requestSchema } from "./types";

const encodeData = (data: CrossChainRequest): Buffer => {
  return Buffer.from(serialize(requestSchema, data));
};

export function hashRequest(request: Req): Buffer {
  return Buffer.from(keccak_256(encodeData(new CrossChainRequest(request))));
}
