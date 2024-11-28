// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import { BaseScript } from "./Base.s.sol";

import { TokenDeployer } from "@axelar-network/axelar-cgp-solidity/contracts/TokenDeployer.sol";

import { AxelarGasService } from "@axelar-network/axelar-cgp-solidity/contracts/gas-service/AxelarGasService.sol";

import { AxelarAuthWeighted } from "@axelar-network/axelar-cgp-solidity/contracts/auth/AxelarAuthWeighted.sol";

import { AxelarGateway } from "@axelar-network/axelar-cgp-solidity/contracts/AxelarGateway.sol";

contract Deploy is BaseScript {
    function run() public broadcast returns (TokenDeployer, AxelarGasService, AxelarAuthWeighted, AxelarGateway) {
        TokenDeployer tokenDeployer = new TokenDeployer();

        AxelarGasService gasService = new AxelarGasService(broadcaster);

        bytes[] memory operators = new bytes[](0);
        AxelarAuthWeighted authWeighted = new AxelarAuthWeighted(operators);

        AxelarGateway axelarGateway = new AxelarGateway(address(authWeighted), address(tokenDeployer));

        return (tokenDeployer, gasService, authWeighted, axelarGateway);
    }
}
