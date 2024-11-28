# Scalar Contracts

Smart contracts for the Scalar Protocol, enabling cross-chain Bitcoin bridging using Axelar's General Message Passing
(GMP).

## Overview

The Scalar Protocol consists of the following main components:

- **ScalarToken**: An ERC20 token representing bridged Bitcoin
- **Protocol**: Core contract handling cross-chain messaging and token minting/burning
- **Axelar Integration**: Uses Axelar's GMP for secure cross-chain communication

## Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- [Bun](https://bun.sh/) (or Node.js)

## Installation

1. Clone the repository:

```sh
git clone https://github.com/scalar-network/scalar-contracts.git
cd scalar-contracts
```

2. Install dependencies:

```sh
bun install
```

## Environment Setup

Create a `.env` file in the root directory with the following variables:

```sh
PRIVATE_KEY=
ANVIL_RPC_URL=
SEPOLIA_RPC_URL=
API_KEY_ETHERSCAN=
```

## Testing

Run all tests:

```sh
make test-all
```

Run specific test:

```sh
make test <test-file>
```

## How to deploy

1. Default deployment:

```sh
make deploy
```

| TOKEN_NAME | TOKEN_SYMBOL | REDEPLOY_AXELAR |
| ---------- | ------------ | --------------- |
| Scalar BTC | sBTC         | true            |

2. Custom deployment:

```sh
make deploy TOKEN_NAME="Pool BTC" TOKEN_SYMBOL="pBTC" REDEPLOY_AXELAR=false
```

The deployment script will automatically detect if you're using a local network (Anvil) on http://localhost:8545 or a
testnet (Sepolia) and deploy accordingly.

### Local Development

Start a local Anvil node:

```sh
make anvil
```

More details [Makefile](Makefile).

## Contract Architecture

### ScalarToken

- ERC20 token with minting and burning capabilities
- Controlled by owner and protocol contract
- Used to represent bridged Bitcoin

### Protocol Contract

- Handles cross-chain message passing via Axelar
- Manages token minting and burning
- Processes Bitcoin PSBT (Partially Signed Bitcoin Transactions)

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details.
