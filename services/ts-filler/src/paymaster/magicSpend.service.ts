import { formatEther, parseEther } from "viem";
import { sleep } from "bun";

import RRC7755Inbox from "../abis/RRC7755Inbox";
import chains from "../chain/chains";
import constants from "../common/constants";
import SignerService from "../signer/signer.service";
import config from "../config";

export default class MagicSpendService {
  private processing = false;

  constructor() {
    this.run();
  }

  private async run(): Promise<void> {
    while (true) {
      await this.poll();
      await sleep(3000);
    }
  }

  private async poll(): Promise<void> {
    if (this.processing) return;
    this.processing = true;

    try {
      await this.monitor();
    } catch (e) {
      console.error(e);
    } finally {
      this.processing = false;
    }
  }

  private async monitor(): Promise<void> {
    // Check paymaster MagicSpend balance on all supported chains (paymaster.getMagicSpendBalance(account, token))
    // If balance is below threshold, send eth to paymaster
    const chainConfigs = Object.values(chains);

    for (const chainConfig of chainConfigs) {
      if (!chainConfig.contracts.entryPoint) continue;

      const signerService = new SignerService(chainConfig);

      const balanceWei = await chainConfig.publicClient.readContract({
        address: chainConfig.contracts.inbox,
        abi: RRC7755Inbox,
        functionName: "getMagicSpendBalance",
        args: [signerService.getFulfillerAddress(), constants.ethAddress],
      });
      const balance = +formatEther(balanceWei);

      if (balance >= config.magicSpendThreshold) continue;

      console.log(
        `Paymaster on chain ${chainConfig.chainId} has insufficient magic spend balance: ${balance}. Topping up now.`
      );

      const txnHash = await signerService.sendTransaction(
        chainConfig.contracts.inbox,
        parseEther(config.magicSpendThreshold.toString())
      );

      if (!txnHash) {
        throw new Error("Failed to send transaction");
      }

      console.log(
        `Sent ${config.magicSpendThreshold} ETH to paymaster. ${txnHash}`
      );
    }
  }
}
