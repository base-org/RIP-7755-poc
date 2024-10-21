"use client";

import { useAccount } from "wagmi";
import { useCallback, useEffect, useState } from "react";
import {
  ContractFunctionParameters,
  createPublicClient,
  formatEther,
  http,
  parseEther,
  zeroAddress,
} from "viem";
import { arbitrumSepolia, baseSepolia } from "viem/chains";
import {
  LifecycleStatus,
  Transaction,
  TransactionButton,
  TransactionStatus,
  TransactionStatusAction,
  TransactionStatusLabel,
} from "@coinbase/onchainkit/transaction";

import Card from "./Card";
import {
  ARBITRUM_SEPOLIA_CHAIN_ID,
  BASE_SEPOLIA_CHAIN_ID,
  baseSepoliaInboxContractAddress,
  baseSepoliaL2OracleContractAddress,
  baseSepoliaL2OracleStorageKey,
  baseSepoliaProverContractAddress,
  ONE_WEEK,
  outboxABI,
  outboxContractAddress,
  rewardAsset,
  TWO_WEEKS,
} from "../constants";

export default function CustomSwap() {
  const { address } = useAccount();

  const [arbBal, setArbBal] = useState<string>("0");
  const [baseBal, setBaseBal] = useState<string>("0");
  const [amount, setAmount] = useState<number | null>(null);

  const arbSepoliaClient = createPublicClient({
    chain: arbitrumSepolia,
    transport: http(),
  });
  const baseSepoliaClient = createPublicClient({
    chain: baseSepolia,
    transport: http(),
  });

  useEffect(() => {
    const interval = setInterval(getBalances, 500);
    return () => clearInterval(interval);
  }, [arbBal, baseBal]);

  async function getBalances() {
    if (!address) return;

    const [arbBalance, baseBalance] = await Promise.all([
      arbSepoliaClient.getBalance({ address }),
      baseSepoliaClient.getBalance({ address }),
    ]);

    setArbBal(formatEther(arbBalance).slice(0, 8));
    setBaseBal(formatEther(baseBalance).slice(0, 8));
  }

  let contracts: ContractFunctionParameters[] = [];

  if (amount) {
    const calls = [
      { to: address, value: parseEther(amount.toString()), data: "0x" },
    ];
    const request = {
      requester: address,
      calls,
      destinationChainId: BASE_SEPOLIA_CHAIN_ID,
      proverContract: baseSepoliaProverContractAddress,
      inboxContract: baseSepoliaInboxContractAddress,
      l2Oracle: baseSepoliaL2OracleContractAddress,
      l2OracleStorageKey: baseSepoliaL2OracleStorageKey,
      rewardAsset,
      rewardAmount: parseEther((amount + 5).toString()), // adding 5 wei as a dummy reward for now
      finalityDelaySeconds: ONE_WEEK,
      nonce: 0,
      expiry: Math.floor(Date.now() / 1000) + TWO_WEEKS,
      precheckContract: zeroAddress,
      precheckData: "0x",
    };
    contracts = [
      {
        address: outboxContractAddress,
        abi: outboxABI,
        functionName: "requestCrossChainCall",
        args: [request],
        value: request.rewardAmount,
      },
    ] as unknown as ContractFunctionParameters[];
  }

  const handleOnStatus = useCallback((status: LifecycleStatus) => {
    console.log("LifecycleStatus", status);
    if (status.statusName === "transactionLegacyExecuted") {
      console.log("SETTING AMOUNT");
      setAmount(null);
    }
  }, []);

  return (
    <div className="flex flex-col items-center w-2/4 p-5 border border-slate-200 rounded-lg">
      <div className="w-full mb-3 text-xl">
        <h1>Bridge ETH</h1>
      </div>
      <div className="w-full">
        <div className="w-full flex flex-col gap-4">
          <Card
            title="Arbitrum Sepolia"
            bal={arbBal}
            disabled={false}
            input={amount}
            setInput={setAmount}
          />
          <Card
            title="Base Sepolia"
            bal={baseBal}
            disabled={true}
            input={amount}
            setInput={setAmount}
          />
        </div>
        <div className="w-full mt-3">
          <Transaction
            chainId={ARBITRUM_SEPOLIA_CHAIN_ID}
            contracts={contracts}
            onStatus={handleOnStatus}
          >
            <TransactionButton text="Bridge" />
            <TransactionStatus>
              <TransactionStatusLabel />
              <TransactionStatusAction />
            </TransactionStatus>
          </Transaction>
        </div>
      </div>
    </div>
  );
}
