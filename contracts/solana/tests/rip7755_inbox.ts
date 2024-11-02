import * as anchor from "@coral-xyz/anchor";
import { BN, Program } from "@coral-xyz/anchor";
import { Rip7755Inbox } from "../target/types/rip_7755_inbox";
import { CallTarget } from "../target/types/call_target";
import { assert, expect } from "chai";

describe("rip7755_inbox", () => {
  // Configure the client to use the local cluster.
  anchor.setProvider(anchor.AnchorProvider.env());

  const target = anchor.workspace.CallTarget as Program<CallTarget>;
  const program = anchor.workspace.Rip7755Inbox as Program<Rip7755Inbox>;
  const programProvider = program.provider as anchor.AnchorProvider;

  const requester = anchor.web3.Keypair.generate();
  const caller = programProvider.wallet;
  const fulfiller = anchor.web3.Keypair.generate();
  const prover = anchor.web3.Keypair.generate();

  let request: any;
  let accounts: any;
  let signers: any;
  let fulfillmentInfo: any;

  beforeEach(() => {
    fulfillmentInfo = anchor.web3.Keypair.generate();

    request = {
      requester: requester.publicKey,
      calls: [
        {
          to: target.programId,
          data: Buffer.from("Hello, world!"),
          value: new BN(0),
        },
      ],
      proverContract: prover.publicKey,
      destinationChainId: new BN(103),
      inboxContract: program.programId,
      l2Oracle: prover.publicKey,
      l2OracleStorageKey: [],
      rewardAsset: prover.publicKey,
      rewardAmount: new BN(0),
      finalityDelaySeconds: new BN(0),
      nonce: new BN(0),
      expiry: new BN(0),
      precheckContract: anchor.web3.PublicKey.default,
      precheckData: Buffer.from([]),
    };
    accounts = {
      fulfillmentInfo: fulfillmentInfo.publicKey,
      caller: caller.publicKey,
    };
    signers = [fulfillmentInfo];
  });

  it("Successfully fulfills a request", async () => {
    await program.methods
      .fulfill(request, fulfiller.publicKey)
      .accounts(accounts)
      .signers(signers)
      .rpc();

    const storedReceipt = await program.account.fulfillmentInfo.fetch(
      fulfillmentInfo.publicKey
    );
    expect(storedReceipt.exists).to.be.true;
    expect(storedReceipt.timestamp).to.not.equal(0);
    expect(storedReceipt.filler).to.eql(fulfiller.publicKey);
  });

  it("Should fail if invalid chain ID", async () => {
    request.destinationChainId = new BN(0);

    await shouldFail(
      program.methods
        .fulfill(request, fulfiller.publicKey)
        .accounts(accounts)
        .signers(signers)
        .rpc(),
      "Invalid chain ID"
    );
  });

  it("Should fail if invalid destination", async () => {
    request.inboxContract = target.programId;

    await shouldFail(
      program.methods
        .fulfill(request, fulfiller.publicKey)
        .accounts(accounts)
        .signers(signers)
        .rpc(),
      "Invalid inbox contract"
    );
  });
});

async function shouldFail(fn: any, expectedError: string) {
  try {
    await fn;
    assert(false, "should've failed but didn't");
  } catch (e) {
    expect(e).to.be.instanceOf(anchor.AnchorError);
    expect((e as anchor.AnchorError).error.errorMessage).to.equal(
      expectedError
    );
  }
}
