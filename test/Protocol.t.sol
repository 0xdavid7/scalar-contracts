// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { IAxelarGasService } from "@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGasService.sol";

import { IAxelarGateway } from "@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGateway.sol";
import { AxelarGateway } from "@axelar-network/axelar-cgp-solidity/contracts/AxelarGateway.sol";
import { AxelarAuthWeighted } from "@axelar-network/axelar-cgp-solidity/contracts/auth/AxelarAuthWeighted.sol";
import { TokenDeployer } from "@axelar-network/axelar-cgp-solidity/contracts/TokenDeployer.sol";
import { Test } from "forge-std/src/Test.sol";
import { sBTC } from "../src/tokens/sBTC.sol";
import { Protocol } from "../src/Protocol.sol";
import { console2 } from "forge-std/src/console2.sol";

contract ProtocolTest is Test {
    sBTC token;
    Protocol protocol;
    address owner;
    address user;
    IAxelarGasService mockGasService;
    AxelarGateway gateway;
    AxelarAuthWeighted authModule;
    TokenDeployer tokenDeployer;

    function setUp() public {
        token = new sBTC();
        owner = token.owner();
        user = address(1);

        // Mock Axelar contracts
        mockGasService = IAxelarGasService(address(0xCAFE));

        // mock operators
        bytes[] memory operators = new bytes[](0);
        authModule = new AxelarAuthWeighted(operators);

        // mock token deployer
        tokenDeployer = new TokenDeployer();

        // mock gateway
        gateway = new AxelarGateway(address(authModule), address(tokenDeployer));

        // Deploy the Protocol contract
        protocol = new Protocol(address(gateway), address(mockGasService), address(token));

        // Mint initial tokens for the user
        token.mint(user, 1000 ether);

        // Ensure user has balance and approval is granted
        vm.startPrank(user);
        token.approve(address(protocol), 1000 ether);
        vm.stopPrank();
    }

    function testUnstake() public {
        // log balance of user and allowance of protocol
        console2.log("user balance: ", token.balanceOf(user));
        console2.log("protocol allowance: ", token.allowance(user, address(protocol)));

        // Initial checks
        uint256 userInitialBalance = token.balanceOf(user);
        assertEq(userInitialBalance, 1000 ether);

        // assert total supply
        assertEq(token.totalSupply(), 1000 ether);

        // Call unstake function as the user
        vm.startPrank(user);
        protocol.unstake("WBitcoin", "0x123", 100 ether, "dummyBtcTxHex");
        vm.stopPrank();

        // Verify balances after unstaking
        uint256 userFinalBalance = token.balanceOf(user);
        uint256 protocolBalance = token.balanceOf(address(protocol));
        uint256 protocolAllowance = token.allowance(user, address(protocol));
        uint256 totalSupply = token.totalSupply();

        console2.log("user balance after unstake: ", userFinalBalance);
        console2.log("protocol balance after unstake: ", protocolBalance);
        console2.log("protocol allowance after unstake: ", protocolAllowance);
        console2.log("total supply after unstake: ", totalSupply);

        assertEq(userFinalBalance, 900 ether);
        assertEq(protocolBalance, 0); // All tokens burnt
        assertEq(protocolAllowance, 900 ether);
        assertEq(totalSupply, 900 ether);
    }
}
