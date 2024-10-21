import {
  bytesToHex,
  encodeAbiParameters,
  keccak256,
  toHex,
  toRlp,
  type Address,
  type Block,
} from "viem";
const { ssz } = await import("@lodestar/types");
const { BeaconBlock } = ssz.deneb;
const { createProof, ProofType } = await import(
  "@chainsafe/persistent-merkle-tree"
);

import type ChainService from "../chain/chain.service";
import constants from "../common/constants";
import type {
  GetStorageProofsInput,
  Proofs,
  StateRootProofReturnType,
} from "../common/types/prover";
import {
  SupportedChains,
  type ActiveChains,
  type GetBeaconRootAndL2TimestampReturnType,
} from "../common/types/chain";
import type {
  ArbitrumProofType,
  OPStackProofType,
} from "../common/types/proof";

export default class ProverService {
  constructor(
    private readonly activeChains: ActiveChains,
    private readonly chainService: ChainService
  ) {}

  async generateProof(
    requestHash: Address
  ): Promise<ArbitrumProofType | OPStackProofType> {
    const beaconData = await this.chainService.getBeaconRootAndL2Timestamp();
    const beaconBlock = await this.chainService.getBeaconBlock(
      beaconData.beaconRoot
    );
    const stateRootInclusion = this.getExecutionStateRootProof(beaconBlock);

    const l1BlockNumber = BigInt(beaconBlock.body.executionPayload.blockNumber);

    const { l2Block, sendRoot, nodeIndex } = await this.chainService.getL2Block(
      l1BlockNumber
    );
    const l2Slot = this.deriveRIP7755VerifierStorageSlot(requestHash);
    // const l2Slot = deriveOpSepoliaWethStorageSlot();

    const storageProofOpts = {
      l1BlockNumber,
      l2Block,
      l2Slot,
      nodeIndex,
    };
    const storageProofs = await this.getStorageProofs(storageProofOpts);

    return this.storeProofObj(
      storageProofs,
      l2Block,
      beaconData,
      stateRootInclusion,
      sendRoot,
      nodeIndex
    );
  }

  private getExecutionStateRootProof(block: any): StateRootProofReturnType {
    console.log("getExecutionStateRootProof");
    const blockView = BeaconBlock.toView(block);
    const path = ["body", "executionPayload", "stateRoot"];
    const pathInfo = blockView.type.getPathInfo(path);
    const proofObj = createProof(blockView.node, {
      type: ProofType.single,
      gindex: pathInfo.gindex,
    }) as any;
    const proof = proofObj.witnesses.map((w: Uint8Array) => bytesToHex(w));
    const leaf = bytesToHex(proofObj.leaf as Uint8Array);
    return { proof, leaf };
  }

  private async getStorageProofs(opts: GetStorageProofsInput): Promise<Proofs> {
    console.log("getStorageProofs");
    const { l1BlockNumber, l2Block, l2Slot, nodeIndex } = opts;
    const dstConfig = this.activeChains.dst;

    const calls = [
      this.activeChains.l1.publicClient.getProof(
        this.buildL1Proof(l1BlockNumber, nodeIndex)
      ),
      dstConfig.publicClient.getProof({
        // address: addresses[dstChain].opSepoliaWethAddr,
        address: dstConfig.contracts.rip7755VerifierContractAddr,
        storageKeys: [l2Slot],
        blockNumber: l2Block.number,
      }),
    ];

    if (dstConfig.chainId === SupportedChains.OptimismSepolia) {
      calls.push(
        dstConfig.publicClient.getProof({
          address: dstConfig.contracts.l2MessagePasserAddr,
          storageKeys: [],
          blockNumber: l2Block.number,
        })
      );
    }

    const storageProofs = await Promise.all(calls);

    const [storageProof, l2StorageProof, l2MessagePasserStorageProof] =
      storageProofs;
    return { storageProof, l2StorageProof, l2MessagePasserStorageProof };
  }

  private buildL1Proof(
    l1BlockNumber: bigint,
    nodeIndex?: bigint
  ): { address: Address; storageKeys: Address[]; blockNumber: bigint } {
    const l1Config = this.activeChains.l1;
    let address = l1Config.contracts.anchorStateRegistryAddr;
    let storageKeys = [constants.slots.anchorStateRegistrySlot];

    if (this.activeChains.dst.chainId === SupportedChains.ArbitrumSepolia) {
      if (!nodeIndex) {
        throw new Error("Node index is required for Arbitrum proofs");
      }
      address = l1Config.contracts.arbRollupAddr;
      const slot = 118n;
      const offset = 2n; // confirmData is offset by 2 slots in Node struct
      const derivedSlotStart = keccak256(
        encodeAbiParameters(
          [{ type: "uint64" }, { type: "uint256" }],
          [nodeIndex, slot]
        )
      );
      const derivedSlot = toHex(BigInt(derivedSlotStart) + offset);
      storageKeys = [derivedSlot];
    }

    return { address, storageKeys, blockNumber: l1BlockNumber };
  }

  private deriveRIP7755VerifierStorageSlot(requestHash: Address): Address {
    console.log("deriveRIP7755VerifierStorageSlot");
    return keccak256(
      encodeAbiParameters(
        [{ type: "bytes32" }, { type: "uint256" }],
        [requestHash, BigInt(constants.slots.fulfillmentInfoSlot)]
      )
    );
  }

  private storeProofObj(
    proofs: Proofs,
    l2Block: Block,
    beaconData: GetBeaconRootAndL2TimestampReturnType,
    stateRootInclusion: StateRootProofReturnType,
    sendRoot?: Address,
    nodeIndex?: bigint
  ): ArbitrumProofType | OPStackProofType {
    console.log("storeProofObj");
    const proofObj: any = {
      l2StateRoot: l2Block.stateRoot,
      l2BlockHash: l2Block.hash,
      stateProofParams: {
        beaconRoot: beaconData.beaconRoot,
        beaconOracleTimestamp: toHex(beaconData.timestampForL2BeaconOracle, {
          size: 32,
        }),
        executionStateRoot: stateRootInclusion.leaf,
        stateRootProof: stateRootInclusion.proof,
      },
      dstL2StateRootProofParams: {
        storageKey: proofs.storageProof.storageProof[0].key,
        storageValue: toHex(proofs.storageProof.storageProof[0].value),
        accountProof: proofs.storageProof.accountProof,
        storageProof: proofs.storageProof.storageProof[0].proof,
      },
      dstL2AccountProofParams: {
        storageKey: proofs.l2StorageProof.storageProof[0].key,
        storageValue: toHex(proofs.l2StorageProof.storageProof[0].value),
        accountProof: proofs.l2StorageProof.accountProof,
        storageProof: proofs.l2StorageProof.storageProof[0].proof,
      },
    };

    if (proofs.l2MessagePasserStorageProof) {
      proofObj["l2MessagePasserStorageRoot"] =
        proofs.l2MessagePasserStorageProof.storageHash;
    }

    if (this.activeChains.dst.chainId === SupportedChains.ArbitrumSepolia) {
      if (!sendRoot) {
        throw new Error("Send Root is required for Arbitrum proofs");
      }
      if (!nodeIndex) {
        throw new Error("Node index is required for Arbitrum proofs");
      }
      proofObj["sendRoot"] = sendRoot;
      if (!l2Block.number) {
        throw new Error("L2Block missing number");
      }
      if (!l2Block.baseFeePerGas) {
        throw new Error("L2Block missing baseFeePerGas");
      }
      if (!l2Block.logsBloom) {
        throw new Error("L2Block missing logsBloom");
      }
      if (!l2Block.nonce) {
        throw new Error("L2Block missing nonce");
      }
      const blockArray = [
        l2Block.parentHash,
        l2Block.sha3Uncles,
        l2Block.miner,
        l2Block.stateRoot,
        l2Block.transactionsRoot,
        l2Block.receiptsRoot,
        l2Block.logsBloom,
        toHex(l2Block.difficulty),
        toHex(l2Block.number),
        toHex(l2Block.gasLimit),
        toHex(l2Block.gasUsed),
        toHex(l2Block.timestamp),
        l2Block.extraData,
        l2Block.mixHash,
        l2Block.nonce,
        toHex(l2Block.baseFeePerGas),
      ];

      if (keccak256(toRlp(blockArray)) !== l2Block.hash) {
        throw new Error("Blockhash mismatch");
      }

      proofObj["encodedBlockArray"] = toRlp(blockArray);
      proofObj["nodeIndex"] = nodeIndex;

      delete proofObj.l2StateRoot;
      delete proofObj.l2BlockHash;
    }

    return proofObj;
  }
}
