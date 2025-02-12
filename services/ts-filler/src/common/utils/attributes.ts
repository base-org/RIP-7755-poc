import { decodeAbiParameters, zeroHash, type Address, type Hex } from "viem";
import bytes32ToAddress from "./bytes32ToAddress";

const REWARD_ATTRIBUTE_SELECTOR = "0xa362e5db";
const DELAY_ATTRIBUTE_SELECTOR = "0x84f550e0";
const L2_ORACLE_ATTRIBUTE_SELECTOR = "0x7ff7245a";
const SHOYU_BASHI_ATTRIBUTE_SELECTOR = "0xda07e15d";

export default class Attributes {
  constructor(private attributes: Hex[]) {}

  count(): number {
    return this.attributes.length;
  }

  getAttributes(): Hex[] {
    return this.attributes;
  }

  getL2Oracle(): Address {
    const attribute = this.getAttributeUnchecked(L2_ORACLE_ATTRIBUTE_SELECTOR);

    const [address] = attribute
      ? decodeAbiParameters(
          [{ type: "bytes32" }],
          ("0x" + attribute.slice(10)) as Hex
        )
      : [zeroHash];

    return bytes32ToAddress(address as Hex);
  }

  getReward(): { asset: Address; amount: bigint } {
    const attribute = this.getAttribute(REWARD_ATTRIBUTE_SELECTOR);

    const [asset, amount] = decodeAbiParameters(
      [{ type: "bytes32" }, { type: "uint256" }],
      ("0x" + attribute.slice(10)) as Hex
    );

    return { asset: bytes32ToAddress(asset), amount };
  }

  getDelay(): { finalityDelaySeconds: number; expiry: number } {
    const attribute = this.getAttribute(DELAY_ATTRIBUTE_SELECTOR);

    const [finalityDelaySeconds, expiry] = decodeAbiParameters(
      [{ type: "uint256" }, { type: "uint256" }],
      ("0x" + attribute.slice(10)) as Hex
    );

    return {
      finalityDelaySeconds: Number(finalityDelaySeconds),
      expiry: Number(expiry),
    };
  }

  getShoyuBashi(): Hex {
    const attribute = this.getAttribute(SHOYU_BASHI_ATTRIBUTE_SELECTOR);

    const [hash] = decodeAbiParameters(
      [{ type: "bytes32" }],
      ("0x" + attribute.slice(10)) as Hex
    );

    return hash;
  }

  private getAttribute(selector: Hex): Hex {
    const attribute = this.getAttributeUnchecked(selector);

    if (!attribute) {
      throw new Error(`Attribute not found: ${selector}`);
    }

    return attribute;
  }

  private getAttributeUnchecked(selector: Hex): Hex | undefined {
    return this.attributes.find((attr) => attr.slice(0, 10) === selector);
  }
}
