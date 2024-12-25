import "dotenv/config";

import { z } from "zod";

const ProjectENVSchema = z.object({
  ETHEREUM_RPC_URL: z.string().min(10),
  PRIVATE_KEY: z.string().min(10),
  PROTOCOL_ADDRESS: z.string().min(10),
  GATEWAY_ADDRESS: z.string().min(10),
});

export const ProjectENV = ProjectENVSchema.parse({
  ETHEREUM_RPC_URL: process.env.ETHEREUM_RPC_URL,
  PRIVATE_KEY: process.env.PRIVATE_KEY,
  PROTOCOL_ADDRESS: process.env.PROTOCOL_ADDRESS,
  GATEWAY_ADDRESS: process.env.GATEWAY_ADDRESS,
});
