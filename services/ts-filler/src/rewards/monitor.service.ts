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
  HashiProofType,
  OPStackProofType,
  ProofType,
} from "../common/types/proof";
import CAIP10 from "../common/utils/caip10";
import HashiProof from "../abis/HashiProof";
import Attributes from "../common/utils/attributes";
import ShoyuBashi from "../abis/ShoyuBashi";
import bytes32ToAddress from "../common/utils/bytes32ToAddress";

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

    await Promise.allSettled(jobs.map((job) => this.handleJob(job)));
  }

  private async handleJob(job: SubmissionType): Promise<void> {
    try {
      const activeChains = {
        src: chains[job.activeChains.src],
        l1: chains[job.activeChains.l1],
        dst: chains[job.activeChains.dst],
      };
      const chainService = new ChainService(activeChains, this.configService);
      const signerService = new SignerService(chains[job.activeChains.src]);
      const proverService = new ProverService(
        activeChains,
        chainService,
        job.devnet
      );
      const { requestHash, sender, receiver, payload, attributes } = job;

      const { proof, l2Block } = await proverService.generateProofWithL2Block(
        requestHash
      );
      const attributesClass = new Attributes(attributes);
      attributesClass.removeFulfiller();

      const usingHashi =
        !activeChains.src.exposesL1State || !activeChains.dst.sharesStateWithL1;

      if (usingHashi) {
        // NOTE: This is only for a proof of concept. We have a mock shoyu bashi contract that allows us to directly set the block hash for the l2 block number.
        // In production, more sophisticated logic will be needed to determine the latest block number accounted for in the Hashi system.
        const shoyuBashi = attributesClass.getShoyuBashi();
        await signerService.sendTransaction(
          bytes32ToAddress(shoyuBashi),
          ShoyuBashi,
          "setHash",
          [activeChains.dst.chainId, l2Block.number as bigint, l2Block.hash]
        );
      }

      const payTo = signerService.getFulfillerAddress();
      const encodedProof = this.encodeProof(proof);

      const functionName = "claimReward";
      const args = [
        sender,
        receiver,
        payload,
        attributesClass.getAttributes(),
        encodedProof,
        payTo,
      ];

      console.log(
        "Proof successfully generated. Sending rewardClaim transaction"
      );

      const senderObj = new CAIP10(sender);

      const txnHash = await signerService.sendTransaction(
        senderObj.getAddress(),
        RIP7755Outbox,
        functionName,
        args
      );

      if (!txnHash) {
        throw new Error("Failed to submit transaction");
      }

      console.log(`Transaction successful: ${txnHash}`);

      await this.dbService.updateRewardClaimed(job._id, txnHash);
    } catch (e) {
      console.error(e);
    }
  }

  private encodeProof(proof: ProofType): EncodeAbiParametersReturnType {
    if (this.isArbitrumProofType(proof)) {
      return encodeAbiParameters(ArbitrumProof, [proof]);
    } else if (this.isOPStackProofType(proof)) {
      return encodeAbiParameters(OPStackProof, [proof]);
    } else if (this.isHashiProofType(proof)) {
      return encodeAbiParameters(HashiProof, [proof]);
    } else {
      throw new Error("Unknown proof type");
    }
  }

  private isArbitrumProofType(proof: ProofType): proof is ArbitrumProofType {
    return (proof as ArbitrumProofType).prevAssertionHash !== undefined;
  }

  private isOPStackProofType(proof: ProofType): proof is OPStackProofType {
    return (proof as OPStackProofType).l2MessagePasserStorageRoot !== undefined;
  }

  private isHashiProofType(proof: ProofType): proof is HashiProofType {
    return (proof as HashiProofType).rlpEncodedBlockHeader !== undefined;
  }
}
