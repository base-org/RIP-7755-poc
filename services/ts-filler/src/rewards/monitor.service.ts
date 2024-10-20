import { encodeAbiParameters } from "viem";

import RIP7755Outbox from "../abis/RIP7755Outbox";
import ChainService from "../chain/chain.service";
import chains from "../chain/chains";
import type ConfigService from "../config/config.service";
import type DBService from "../database/db.service";
import ProverService from "../prover/prover.service";
import SignerService from "../signer/signer.service";
import type { SubmissionType } from "../types/submission";

export default class RewardMonitorService {
  private processing = false;

  constructor(
    private readonly dbService: DBService,
    private readonly configService: ConfigService
  ) {
    setInterval(() => this.poll(), 3000);
  }

  async poll() {
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

  private async monitor() {
    const jobs = await this.dbService.getClaimableRewards();

    if (jobs.length === 0) return;

    console.log(`Found ${jobs.length} rewards to claim`);

    await this.handleJobs(jobs);
  }

  private async handleJobs(jobs: SubmissionType[]) {
    for (let i = 0; i < jobs.length; i++) {
      await this.handleJob(jobs[i]);
    }
  }

  private async handleJob(job: SubmissionType) {
    const activeChains = {
      src: chains[job.activeChains.src],
      l1: chains[job.activeChains.l1],
      dst: chains[job.activeChains.dst],
    };
    const chainService = new ChainService(activeChains, this.configService);
    const signerService = new SignerService(chains[job.activeChains.dst]);
    const proverService = new ProverService(activeChains, chainService);
    const { requestHash, request } = job;

    const [fulfillmentInfo, proof] = await Promise.all([
      chainService.getFulfillmentInfo(requestHash),
      proverService.generateProof(requestHash),
    ]);
    const payTo = signerService.getFulfillerAddress();

    const args = [
      request,
      fulfillmentInfo,
      encodeAbiParameters(
        [
          {
            name: "request",
            type: "tuple",
            internalType: "struct CrossChainRequest",
            components: [
              { name: "requester", type: "address", internalType: "address" },
              {
                name: "calls",
                type: "tuple[]",
                internalType: "struct Call[]",
                components: [
                  { name: "to", type: "address", internalType: "address" },
                  { name: "data", type: "bytes", internalType: "bytes" },
                  { name: "value", type: "uint256", internalType: "uint256" },
                ],
              },
              {
                name: "proverContract",
                type: "address",
                internalType: "address",
              },
              {
                name: "destinationChainId",
                type: "uint256",
                internalType: "uint256",
              },
              {
                name: "inboxContract",
                type: "address",
                internalType: "address",
              },
              { name: "l2Oracle", type: "address", internalType: "address" },
              {
                name: "l2OracleStorageKey",
                type: "bytes32",
                internalType: "bytes32",
              },
              { name: "rewardAsset", type: "address", internalType: "address" },
              {
                name: "rewardAmount",
                type: "uint256",
                internalType: "uint256",
              },
              {
                name: "finalityDelaySeconds",
                type: "uint256",
                internalType: "uint256",
              },
              { name: "nonce", type: "uint256", internalType: "uint256" },
              { name: "expiry", type: "uint256", internalType: "uint256" },
              {
                name: "precheckContract",
                type: "address",
                internalType: "address",
              },
              { name: "precheckData", type: "bytes", internalType: "bytes" },
            ],
          },
        ],
        [proof]
      ),
      payTo,
    ];

    const txnHash = await signerService.sendTransaction(
      activeChains.src.contracts.outbox,
      RIP7755Outbox,
      "claimReward",
      args
    );

    console.log({ txnHash });

    if (!txnHash) {
      // Probably want to retry here
      throw new Error("Failed to submit transaction");
    }

    await this.dbService.updateRewardClaimed(job._id, txnHash);
  }
}
