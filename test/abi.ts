export const erc20CrossChainABI = [
  {
    type: "function",
    name: "transferRemote",
    inputs: [
      { name: "destinationChain", type: "string" },
      { name: "destinationContractAddress", type: "address" },
      { name: "amount", type: "uint256" },
      { name: "encodedMetadata", type: "bytes" },
    ],
    outputs: [],
    stateMutability: "nonpayable",
  },
] as const;
