import * as anchor from "@coral-xyz/anchor";
import { BN, Program } from "@coral-xyz/anchor";
import { PublicKey } from "@solana/web3.js";
import { assert, expect } from "chai";

import { Rip7755Inbox } from "../target/types/rip_7755_inbox";
import { CallTarget } from "../target/types/call_target";
import { Precheck } from "../target/types/precheck";

describe("rip7755_inbox", () => {
  // Configure the client to use the local cluster.
  anchor.setProvider(anchor.AnchorProvider.env());

  const target = anchor.workspace.CallTarget as Program<CallTarget>;
  const program = anchor.workspace.Rip7755Inbox as Program<Rip7755Inbox>;
  const precheck = anchor.workspace.Precheck as Program<Precheck>;
  const programProvider = program.provider as anchor.AnchorProvider;

  const requester = anchor.web3.Keypair.generate();
  const caller = programProvider.wallet;
  const fulfiller = anchor.web3.Keypair.generate();

  let request: any;
  let accounts: any;
  let signers: any;
  let fulfillmentInfo: any;
  let transactionAccounts: any;
  let remainingAccounts: any;
  let nonce = new BN(0);

  beforeEach(() => {
    nonce = nonce.add(new BN(1));
    request = {
      requester: requester.publicKey,
      calls: [
        {
          to: target.programId,
          data: target.coder.instruction.encode("makeCall", {
            data: Buffer.from([0]),
          }),
          value: new BN(0),
        },
      ],
      destinationChainId: new BN(103),
      inboxContract: program.programId,
      l2Oracle: fulfiller.publicKey,
      l2OracleStorageKey: new Array(32).fill(0),
      rewardAsset: fulfiller.publicKey,
      rewardAmount: new BN(0),
      finalityDelaySeconds: new BN(0),
      nonce,
      expiry: new BN(0),
      extraData: Buffer.from(Buffer.from([])),
    };
    [fulfillmentInfo] = anchor.web3.PublicKey.findProgramAddressSync(
      [request.requester.toBuffer(), request.nonce.toBuffer("be", 8)],
      program.programId
    );
    accounts = {
      fulfillmentInfo: fulfillmentInfo,
      caller: caller.publicKey,
    };
    signers = [];
    transactionAccounts = [
      {
        isSigner: true,
        isWritable: true,
        pubkey: caller.publicKey,
      },
    ];
    remainingAccounts = [
      {
        isSigner: true,
        isWritable: true,
        pubkey: caller.publicKey,
      },
      {
        isSigner: false,
        isWritable: false,
        pubkey: new PublicKey(target.programId),
      },
    ];
  });

  it("Successfully fulfills a request", async () => {
    await program.methods
      .fulfill(request, fulfiller.publicKey, transactionAccounts)
      .accounts(accounts)
      .remainingAccounts(remainingAccounts)
      .signers(signers)
      .rpc();

    const storedReceipt = await program.account.fulfillmentInfo.fetch(
      fulfillmentInfo
    );
    expect(storedReceipt.timestamp).to.not.equal(0);
    expect(storedReceipt.filler).to.eql(fulfiller.publicKey);
  });

  it("Should fail if invalid chain ID", async () => {
    request.destinationChainId = new BN(0);

    await shouldFail(
      program.methods
        .fulfill(request, fulfiller.publicKey, transactionAccounts)
        .accounts(accounts)
        .remainingAccounts(remainingAccounts)
        .signers(signers)
        .rpc(),
      "Invalid chain ID"
    );
  });
  it("Should fail if invalid destination", async () => {
    request.inboxContract = target.programId;
    await shouldFail(
      program.methods
        .fulfill(request, fulfiller.publicKey, transactionAccounts)
        .accounts(accounts)
        .remainingAccounts(remainingAccounts)
        .signers(signers)
        .rpc(),
      "Invalid inbox contract"
    );
  });

  it("Should fail if invalid precheck data", async () => {
    request.extraData = [Buffer.from([10])];

    await shouldFail(
      program.methods
        .fulfill(request, fulfiller.publicKey, transactionAccounts)
        .accounts(accounts)
        .remainingAccounts(remainingAccounts)
        .signers(signers)
        .rpc(),
      "Invalid precheck data"
    );
  });

  it("Should fail if invalid precheck", async () => {
    request.extraData = [target.programId.toBuffer()];

    await shouldFail(
      program.methods
        .fulfill(request, fulfiller.publicKey, transactionAccounts)
        .accounts(accounts)
        .remainingAccounts(remainingAccounts)
        .signers(signers)
        .rpc(),
      "Invalid precheck contract"
    );
  });

  it("Should fail if precheck fails", async () => {
    request.extraData = [precheck.programId.toBuffer()];
    request.rewardAmount = new BN(1);

    await shouldFail(
      program.methods
        .fulfill(request, fulfiller.publicKey, transactionAccounts)
        .accounts(accounts)
        .remainingAccounts(remainingAccounts)
        .signers(signers)
        .rpc(),
      "Precheck failed"
    );
  });

  it("Should revert if receipt already exists", async () => {
    await program.methods
      .fulfill(request, fulfiller.publicKey, transactionAccounts)
      .accounts(accounts)
      .remainingAccounts(remainingAccounts)
      .signers(signers)
      .rpc();
    await shouldFail(
      program.methods
        .fulfill(request, fulfiller.publicKey, transactionAccounts)
        .accounts(accounts)
        .remainingAccounts(remainingAccounts)
        .signers(signers)
        .rpc(),
      ""
    );
  });
});

async function shouldFail(fn: any, expectedError: string) {
  try {
    await fn;
    assert(false, "should've failed but didn't");
  } catch (e) {
    if (expectedError != "") {
      expect(e).to.be.instanceOf(anchor.AnchorError);
      expect((e as anchor.AnchorError).error.errorMessage).to.equal(
        expectedError
      );
    }
  }
}
