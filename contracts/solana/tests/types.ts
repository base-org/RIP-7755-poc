import { PublicKey } from "@solana/web3.js";
import { Schema } from "borsh";

export type Req = {
  requester: PublicKey;
  calls: PreCall[];
  sourceChainId: bigint;
  origin: PublicKey;
  destinationChainId: bigint;
  inboxContract: PublicKey;
  l2Oracle: PublicKey;
  l2OracleStorageKey: Uint8Array;
  rewardAsset: PublicKey;
  rewardAmount: bigint;
  finalityDelaySeconds: bigint;
  nonce: bigint;
  expiry: bigint;
  extraData: Buffer[];
};

type PreCall = { to: PublicKey; data: Uint8Array; value: bigint };

class Call {
  to: Buffer;
  data: Buffer;
  value: bigint;

  constructor(props: PreCall) {
    this.to = props.to.toBuffer();
    this.data = Buffer.from(props.data);
    this.value = props.value;
  }
}

export class CrossChainRequest {
  requester: Buffer;
  calls: Call[];
  sourceChainId: bigint;
  origin: Buffer;
  destinationChainId: bigint;
  inboxContract: Buffer;
  l2Oracle: Buffer;
  l2OracleStorageKey: Uint8Array;
  rewardAsset: Buffer;
  rewardAmount: bigint;
  finalityDelaySeconds: bigint;
  nonce: bigint;
  expiry: bigint;
  extraData: Buffer[];

  constructor(props: Req) {
    this.requester = props.requester.toBuffer();
    this.calls = props.calls.map((call) => new Call(call));
    this.sourceChainId = props.sourceChainId;
    this.origin = props.origin.toBuffer();
    this.destinationChainId = props.destinationChainId;
    this.inboxContract = props.inboxContract.toBuffer();
    this.l2Oracle = props.l2Oracle.toBuffer();
    this.l2OracleStorageKey = props.l2OracleStorageKey;
    this.rewardAsset = props.rewardAsset.toBuffer();
    this.rewardAmount = props.rewardAmount;
    this.finalityDelaySeconds = props.finalityDelaySeconds;
    this.nonce = props.nonce;
    this.expiry = props.expiry;
    this.extraData = props.extraData.map((data) => Buffer.from(data));
  }
}

const pKey = { array: { type: "u8", len: 32 } };
const buff = { array: { type: "u8" } };
const callSchema = { struct: { to: pKey, data: buff, value: "u64" } };
export const requestSchema: Schema = {
  struct: {
    requester: pKey,
    calls: { array: { type: callSchema } },
    sourceChainId: "u64",
    origin: pKey,
    destinationChainId: "u64",
    inboxContract: pKey,
    l2Oracle: pKey,
    l2OracleStorageKey: { array: { type: "u8", len: 32 } },
    rewardAsset: pKey,
    rewardAmount: "u64",
    finalityDelaySeconds: "u64",
    nonce: "u64",
    expiry: "u64",
    extraData: { array: { type: buff } },
  },
};
