import {
  createWalletClient,
  http,
  type Account,
  type Address,
  type WalletClient,
} from "viem";
import { privateKeyToAccount } from "viem/accounts";

import type { ChainConfig } from "../types/chain";

export default class SignerService {
  private account: Account;
  private signer: WalletClient;

  constructor(private readonly chain: ChainConfig) {
    // WARNING: DO NOT DO THIS IN PRODUCTION!! This is only for a proof-of-concept
    // Production signer apps should use a secure key management service like https://aws.amazon.com/kms/
    const privateKey = process.env.PRIVATE_KEY as Address;

    if (!privateKey) {
      throw new Error("No signer private key found");
    }

    this.account = privateKeyToAccount(privateKey);
    this.signer = createWalletClient({
      chain: this.chain.publicClient.chain,
      transport: http(this.chain.rpcUrl),
    });
  }

  getFulfillerAddress(): Address {
    return this.account.address;
  }

  async sendTransaction(
    to: Address,
    abi: any,
    functionName: string,
    args: any[],
    value = 0n
  ): Promise<Address> {
    const txHash = await this.signer.writeContract({
      address: to,
      abi,
      functionName,
      args,
      value,
      chain: this.chain.publicClient.chain,
      account: this.account,
    });
    return txHash;
  }
}
