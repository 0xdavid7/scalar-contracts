// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

import { Test } from "forge-std/src/Test.sol";
import { ScalarGateway } from "../src/ScalarGateway.sol";
import { AxelarAuthWeighted } from "@axelar-network/axelar-cgp-solidity/contracts/auth/AxelarAuthWeighted.sol";
import { TokenDeployer } from "@axelar-network/axelar-cgp-solidity/contracts/TokenDeployer.sol";
import { Test } from "forge-std/src/Test.sol";
import { console2 } from "forge-std/src/console2.sol";

contract ScalarGatewayTest is Test {
    ScalarGateway public gateway;

    address public broadcaster;

    function setUp() public {
        // Fork mainnet
        vm.createSelectFork("mainnet");

        // Setup test accounts
        broadcaster = makeAddr("broadcaster");
        vm.prank(broadcaster);

        // mock operators
        bytes[] memory operators = new bytes[](0);
        AxelarAuthWeighted authModule = new AxelarAuthWeighted(operators);

        // mock token deployer
        TokenDeployer tokenDeployer = new TokenDeployer();

        // mock gateway
        gateway = new ScalarGateway(address(authModule), address(tokenDeployer));

        // Fund test accounts with ETH
        vm.deal(broadcaster, 100 ether);
    }

    function test_getSession() public {
        vm.expectRevert(ScalarGateway.NotInitializedSession.selector);
        gateway.getSession(keccak256("test"));
    }

    function testEncodePacked() public pure {
        bytes1 data1 = 0x01;
        bytes2 data2 = 0x0102;
        bytes3 data3 = 0x010203;
        string memory data4 = "0x04";
        bytes memory data = abi.encodePacked(data1, data2, data3, data4);
        console2.logBytes(data);
    }
}
