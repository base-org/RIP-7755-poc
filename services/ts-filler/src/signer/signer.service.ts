import type { Address } from "viem";

// TODO
export default class SignerService {
  getFulfillerAddress(): Address {
    return "0x";
  }

  async sendTransaction(
    chainId: number,
    to: Address,
    functionName: string,
    args: any[],
    value = 0n
  ): Promise<boolean> {
    return true;
  }
}
