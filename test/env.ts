import { z } from 'zod'

const EnvSchema = z.object({
    PRIVATE_KEY: z.string().length(66).startsWith('0x'),
    ALCHEMY_API_KEY: z.string().min(1),
    GATEWAY_CONTRACT_ADDRESS: z.string().length(42).startsWith('0x'),
})

export const ProjectEnv = EnvSchema.parse({
    PRIVATE_KEY: process.env.PRIVATE_KEY,
    ALCHEMY_API_KEY: process.env.ALCHEMY_API_KEY,
    GATEWAY_CONTRACT_ADDRESS: process.env.GATEWAY_CONTRACT_ADDRESS,
})