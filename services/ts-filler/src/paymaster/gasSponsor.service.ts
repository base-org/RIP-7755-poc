import { formatEther, parseEther } from "viem";
import { sleep } from "bun";

import EntryPoint from "../abis/EntryPoint";
import chains from "../chain/chains";
import SignerService from "../signer/signer.service";
import config from "../config";
import RRC7755Inbox from "../abis/RRC7755Inbox";

export default class GasSponsorService {
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
    // Check paymaster gas balance on all supported chains (entryPoint.balanceOf(inbox))
    // If balance is below threshold, send eth to paymaster
    const chainConfigs = Object.values(chains);

    for (const chainConfig of chainConfigs) {
      if (!chainConfig.contracts.entryPoint) continue;

      const signerService = new SignerService(chainConfig);

      const balanceWei = await chainConfig.publicClient.readContract({
        address: chainConfig.contracts.entryPoint,
        abi: EntryPoint,
        functionName: "balanceOf",
        args: [chainConfig.contracts.inbox],
      });
      const balance = +formatEther(balanceWei);

      if (balance >= config.gasSponsorThreshold) continue;

      console.log(
        `Paymaster on chain ${chainConfig.chainId} has insufficient gas balance: ${balance}. Topping up now.`
      );

      const functionName = "entryPointDeposit";
      const args = [parseEther(config.gasSponsorThreshold.toString())];
      const txnHash = await signerService.writeContract(
        chainConfig.contracts.inbox,
        RRC7755Inbox,
        functionName,
        args
      );

      if (!txnHash) {
        throw new Error("Failed to send transaction");
      }

      console.log(
        `Sent ${config.gasSponsorThreshold} ETH to entryPoint for paymaster gas sponsorship. ${txnHash}`
      );
    }
  }
}
