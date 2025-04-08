// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

import { Test } from "forge-std/src/Test.sol";
import { ScalarGateway } from "../src/ScalarGateway.sol";
import { AxelarAuthWeighted } from "@axelar-network/axelar-cgp-solidity/contracts/auth/AxelarAuthWeighted.sol";
import { TokenDeployer } from "@axelar-network/axelar-cgp-solidity/contracts/TokenDeployer.sol";
import { Test } from "forge-std/src/Test.sol";
import { console2 } from "forge-std/src/console2.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract ScalarGatewayTest is Test {
  ScalarGateway public gateway;
  AxelarAuthWeighted public auth;
  TokenDeployer public tokenDeployer;

  address public owner;
  address public broadcaster;
  address[] public operators;
  uint256[] public weights;
  uint256 constant OPERATOR_COUNT = 4;
  uint256 constant THRESHOLD = 4000;

  function setUp() public {
    // Fork mainnet
    vm.createSelectFork("mainnet");

    operators = new address[](OPERATOR_COUNT);
    weights = new uint256[](OPERATOR_COUNT);

    for (uint256 i = 0; i < OPERATOR_COUNT; i++) {
      string memory operatorName = string(abi.encodePacked("operator", Strings.toString(i)));
      console2.log(operatorName);
      operators[i] = makeAddr(operatorName);
      weights[i] = 1000 * (i + 1);
    }

    bytes memory ops = abi.encode(operators, weights, THRESHOLD);

    bytes[] memory recentOps = new bytes[](1);
    recentOps[0] = ops;

    auth = new AxelarAuthWeighted(new bytes[](0));
    auth.transferOperatorship(ops);
   
    tokenDeployer = new TokenDeployer();

    gateway = new ScalarGateway(address(auth), address(tokenDeployer));

  }

  function testGateway() public view {
    console2.log("testGateway");
    console2.log("broadcaster", broadcaster);
    console2.log("OPERATOR_COUNT", OPERATOR_COUNT);
    console2.log("gateway", address(gateway));
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
