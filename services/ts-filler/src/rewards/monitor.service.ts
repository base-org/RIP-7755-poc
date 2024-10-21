import { encodeAbiParameters, type EncodeAbiParametersReturnType } from "viem";

import RIP7755Outbox from "../abis/RIP7755Outbox";
import ChainService from "../chain/chain.service";
import chains from "../chain/chains";
import type ConfigService from "../config/config.service";
import type DBService from "../database/db.service";
import ProverService from "../prover/prover.service";
import SignerService from "../signer/signer.service";
import type { SubmissionType } from "../common/types/submission";
import ArbitrumProof from "../abis/ArbitrumProof";
import OPStackProof from "../abis/OPStackProof";
import type {
  ArbitrumProofType,
  OPStackProofType,
} from "../common/types/proof";

export default class RewardMonitorService {
  private processing = false;

  constructor(
    private readonly dbService: DBService,
    private readonly configService: ConfigService
  ) {
    setInterval(() => this.poll(), 3000);
  }

  async poll(): Promise<void> {
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
    const jobs = await this.dbService.getClaimableRewards();

    if (jobs.length === 0) return;

    console.log(`Found ${jobs.length} rewards to claim`);

    await this.handleJobs(jobs);
  }

  private async handleJobs(jobs: SubmissionType[]): Promise<void> {
    for (let i = 0; i < jobs.length; i++) {
      await this.handleJob(jobs[i]);
    }
  }

  private async handleJob(job: SubmissionType): Promise<void> {
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

    const encodedProof = this.encodeProof(proof);

    const functionName = "claimReward";
    const args = [request, fulfillmentInfo, encodedProof, payTo];

    const txnHash = await signerService.sendTransaction(
      activeChains.src.contracts.outbox,
      RIP7755Outbox,
      functionName,
      args
    );

    console.log({ txnHash });

    if (!txnHash) {
      // Probably want to retry here
      throw new Error("Failed to submit transaction");
    }

    await this.dbService.updateRewardClaimed(job._id, txnHash);
  }

  private encodeProof(
    proof: ArbitrumProofType | OPStackProofType
  ): EncodeAbiParametersReturnType {
    if (this.isArbitrumProofType(proof)) {
      return encodeAbiParameters(ArbitrumProof, [proof]);
    } else if (this.isOPStackProofType(proof)) {
      return encodeAbiParameters(OPStackProof, [proof]);
    } else {
      throw new Error("Unknown proof type");
    }
  }

  private isArbitrumProofType(
    proof: ArbitrumProofType | OPStackProofType
  ): proof is ArbitrumProofType {
    return (proof as ArbitrumProofType).nodeIndex !== undefined;
  }

  private isOPStackProofType(
    proof: ArbitrumProofType | OPStackProofType
  ): proof is OPStackProofType {
    return (proof as OPStackProofType).l2StateRoot !== undefined;
  }
}
