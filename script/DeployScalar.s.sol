// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import { BaseScript } from "./Base.s.sol";

import { TokenDeployer } from "@axelar-network/axelar-cgp-solidity/contracts/TokenDeployer.sol";

import { AxelarAuthWeighted } from "@axelar-network/axelar-cgp-solidity/contracts/auth/AxelarAuthWeighted.sol";

import { ScalarGateway } from "../src/ScalarGateway.sol";

contract Deploy is BaseScript {
  function run() public broadcast returns (TokenDeployer, AxelarAuthWeighted, ScalarGateway) {
    TokenDeployer tokenDeployer = new TokenDeployer();
    bytes[] memory operators = new bytes[](0);
    AxelarAuthWeighted authWeighted = new AxelarAuthWeighted(operators);

    ScalarGateway gateway = new ScalarGateway(address(authWeighted), address(tokenDeployer));

    return (tokenDeployer, authWeighted, gateway);
  }
}
