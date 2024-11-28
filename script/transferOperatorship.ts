// import fs from "fs";

// import { config } from "dotenv";

// config();

// import AXELAR_AUTH_WEIGHTED_ABI_JSON from "../out/AxelarAuthWeighted.sol/AxelarAuthWeighted.json";
// import { privateKeyToAccount } from "viem/accounts";
// import {
//   createPublicClient,
//   createWalletClient,
//   encodeFunctionData,
//   http,
// } from "viem";
// import { sepolia } from "viem/chains";
// import { computeAddress, ethers } from "ethers";

// const AXELAR_AUTH_WEIGHTED_ABI = AXELAR_AUTH_WEIGHTED_ABI_JSON.abi;

// async function main() {
//   // TODO
//   const privKey = "0x" as `0x${string}`;
//   const rpc = "";
//   const authWeightedAddress = "" as `0x${string}`;

//   const walletClient = createWalletClient({
//     account: privateKeyToAccount(privKey),
//     chain: sepolia, // TODO:
//     transport: http(),
//   });

//   const publicClient = createPublicClient({
//     chain: sepolia, // TODO:
//     transport: http(),
//   });

//   const res = (await publicClient.readContract({
//     address: authWeightedAddress,
//     abi: AXELAR_AUTH_WEIGHTED_ABI,
//     functionName: "currentEpoch",
//   })) as bigint;

//   console.log({ currentEpoch: res });

//   const currentHash = await publicClient.readContract({
//     address: authWeightedAddress,
//     abi: AXELAR_AUTH_WEIGHTED_ABI,
//     functionName: "hashForEpoch",
//     args: [res],
//   });

//   console.log(`Current Epoch: ${res.toString()}, Hash: ${currentHash}`);

//   try {
//     // TODO: Prepare params

//     const [newOperators, newWeights, newThreshold] = readOperatorsInfo(keyPath);

//     // Extracting addresses and powers
//     console.log(newOperators);
//     console.log(newWeights);
//     console.log(newThreshold);

//     let combinedArray = (newOperators as `0x${string}`[]).map(
//       (address, index) => {
//         return {
//           address: address,
//           weight: newWeights[index],
//         };
//       }
//     ) as { address: `0x${string}`; weight: bigint }[];

//     combinedArray.sort((a, b) => {
//       if (a.address.toLowerCase() < b.address.toLowerCase()) return -1;
//       if (a.address.toLowerCase() > b.address.toLowerCase()) return 1;
//       return 0;
//     });

//     const sortedOperators = combinedArray.map((item) => item.address);
//     const sortedWeights = combinedArray.map((item) => item.weight);
//     const encodedParams = encodeFunctionData({
//       abi: [
//         {
//           inputs: [
//             { type: "address[]", name: "operators" },
//             { type: "uint256[]", name: "weights" },
//             { type: "uint256", name: "threshold" },
//           ],
//           name: "transferOperatorship",
//           outputs: [],
//           type: "function",
//           stateMutability: "nonpayable",
//         },
//       ],
//       functionName: "transferOperatorship",
//       args: [sortedOperators, sortedWeights, newThreshold],
//     });

//     // Call Transfer Operatorship
//     const txTransferOpShip = await walletClient.writeContract({
//       address: authWeightedAddress,
//       abi: AXELAR_AUTH_WEIGHTED_ABI,
//       functionName: "transferOperatorship",
//       args: [encodedParams],
//       gas: 3000000n,
//     });

//     console.log("Transaction hash:", txTransferOpShip);

//     await publicClient.waitForTransactionReceipt({ hash: txTransferOpShip });
//     console.log("Transaction confirmed");
//   } catch (error) {
//     console.error("Error executing transaction:", error);
//   }
// }

// function readOperatorsInfo(keyPath: string) {
//   console.log("Key file path:", keyPath);
//   const data = fs.readFileSync(keyPath, "utf8");
//   const jsonData = JSON.parse(data);

//   // Extract the validators data
//   const threshold = jsonData.threshold_weight;
//   const operators = jsonData.participants.map(
//     (participant: { pub_key: string }) => {
//       const pubKey = "0x" + participant.pub_key;
//       return computeAddress(pubKey);
//     }
//   );
//   const weights = jsonData.participants.map(
//     (participant: { weight: bigint }) => {
//       return participant.weight;
//     }
//   );
//   return [operators, weights, threshold];
// }

// main()
//   .then(() => process.exit(0))
//   .catch((error) => {
//     console.error(error);
//     process.exit(1);
//   });
