import { sha256, encodePacked, type Hex } from "viem";

import constants from "../constants";

export default function deriveBeaconRoot(curr: Hex): Hex {
  let index = 6434;
  const types = ["bytes32", "bytes32"];

  for (let i = 0; i < constants.mockL1StateRootProof.length; i++) {
    const preImage = [constants.mockL1StateRootProof[i], curr];

    if ((index & 1) === 0) {
      preImage.reverse();
    }

    curr = sha256(encodePacked(types, preImage));

    index >>= 1;
  }

  return curr;
}
