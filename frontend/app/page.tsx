"use client";

import {
  ConnectWallet,
  ConnectWalletText,
  Wallet,
  WalletDropdown,
  WalletDropdownLink,
  WalletDropdownDisconnect,
} from "@coinbase/onchainkit/wallet";
import {
  Address,
  Avatar,
  Name,
  Identity,
  EthBalance,
} from "@coinbase/onchainkit/identity";
import { useAccount } from "wagmi";

import ImageSvg from "./svg/Image";
import OnchainkitSvg from "./svg/OnchainKit";
import CustomSwap from "./components/CustomSwap";

export default function App() {
  const { address } = useAccount();

  return (
    <div className="flex flex-col min-h-screen bg-background font-sans">
      <header className="pt-4 pr-4 w-full flex justify-end">
        <div className="wallet-container">
          <Wallet>
            <ConnectWallet>
              <Avatar className="h-6 w-6" />
              <Name className="text-white" />
            </ConnectWallet>
            <WalletDropdown>
              <Identity className="px-4 pt-3 pb-2" hasCopyAddressOnClick>
                <Avatar />
                <Name />
                <Address />
                <EthBalance />
              </Identity>
              <WalletDropdownLink
                icon="wallet"
                href="https://keys.coinbase.com"
                target="_blank"
                rel="noopener noreferrer"
              >
                Wallet
              </WalletDropdownLink>
              <WalletDropdownDisconnect />
            </WalletDropdown>
          </Wallet>
        </div>
      </header>

      <main className="flex-grow flex flex-col items-center justify-center w-full px-4">
        <div className="text-center mb-8">
          <h1 className="font-sans font-semibold text-xl">RIP-7755 Demo</h1>
        </div>
        <div className="w-full max-w-4xl flex justify-center">
          {address ? (
            <CustomSwap />
          ) : (
            <Wallet>
              <ConnectWallet>
                <Avatar className="h-6 w-6" />
                <Name />
              </ConnectWallet>
            </Wallet>
          )}
        </div>
      </main>

      <footer className="flex justify-center items-center p-8 w-full">
        <p className="text-white mr-1">Powered by</p>
        <a
          target="_blank"
          rel="_template"
          href="https://onchainkit.xyz"
          className="flex items-center"
        >
          <OnchainkitSvg className="text-white" />
        </a>
      </footer>
    </div>
  );
}
