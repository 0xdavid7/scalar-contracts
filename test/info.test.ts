// import { describe, test } from "bun:test";
// import { sepolia } from "viem/chains";
// import { ERC20CrossChainABI } from "./abi";
// import { getEthersSigner } from "./etheres";
// import { getTestSuite } from "./setup";

// const { contractAddress, account, publicClient, walletClient } = getTestSuite();

// describe("ERC20CrossChain", () => {
//   test("info", async () => {
//     // Get token info

//     const name = await publicClient.readContract({
//       address: contractAddress as `0x${string}`,
//       abi: ERC20CrossChainABI,
//       functionName: "name",
//     });

//     const symbol = await publicClient.readContract({
//       address: contractAddress as `0x${string}`,
//       abi: ERC20CrossChainABI,
//       functionName: "symbol",
//     });

//     const decimals = await publicClient.readContract({
//       address: contractAddress as `0x${string}`,
//       abi: ERC20CrossChainABI,
//       functionName: "decimals",
//     });

//     const balanceOf = await publicClient.readContract({
//       address: contractAddress as `0x${string}`,
//       abi: ERC20CrossChainABI,
//       functionName: "balanceOf",
//       args: [account.address],
//     });

//     console.log({
//       name,
//       symbol,
//       decimals,
//       balanceOf,
//     });

//     console.log("contract address", contractAddress);
//   });

//   //    // TODO: Remove this. This is for testing.
//   //    function faucet(uint256 amount) external {
//   //     _mint(msg.sender, amount);
//   //   }

//   test("faucet", async () => {
//     const { request } = await publicClient.simulateContract({
//       address: contractAddress as `0x${string}`,
//       abi: ERC20CrossChainABI,
//       functionName: "faucet",
//       args: [100_000n],
//       account: account.address,
//     });

//     console.log("tx", request);

//     const nonce = await publicClient.getTransactionCount({
//       address: account.address,
//     });

//     const signedTx = await walletClient.signTransaction({
//       data: "0x5791589700000000000000000000000000000000000000000000000000000000000186a0",
//       from: "0x24a1dB57Fa3ecAFcbaD91d6Ef068439acEeAe090",
//       gas: 100_000n,
//       to: "0xad4f02e1990be21241909fd9aba06d358e1c6eb2",
//       value: 0n,
//       chainId: sepolia.id,
//       gasPrice: 100_000n,
//       nonce: nonce,
//     });

//     console.log("signedTx", signedTx);

//     const txHash = await walletClient.sendRawTransaction({
//       serializedTransaction: signedTx,
//     });
//     console.log("Transaction Hash:", txHash);

//     const receipt = await publicClient.waitForTransactionReceipt({
//       hash: txHash,
//     });

//     console.log("receipt", receipt);
//   }, 900_000);
// });
