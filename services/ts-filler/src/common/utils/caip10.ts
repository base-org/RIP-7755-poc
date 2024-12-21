import type { Address } from "viem";

export default class CAIP10 {
  private readonly tag: string;
  private readonly chainId: string;
  private readonly address: Address;

  constructor(value: string) {
    const [tag, chainId, address] = value.split(":");

    this.tag = tag;
    this.chainId = chainId;
    this.address = address as Address;
  }

  getChainId(): number {
    return Number(this.chainId);
  }

  getCaip2(): string {
    return `${this.tag}:${this.chainId}`;
  }

  getAddress(): Address {
    return this.address;
  }

  format(): string {
    return `${this.tag}:${this.chainId}:${this.address}`;
  }
}
