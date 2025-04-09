// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

import { Test } from "forge-std/src/Test.sol";
import { ScalarGateway } from "../src/ScalarGateway.sol";
import { AxelarAuthWeighted } from "@axelar-network/axelar-cgp-solidity/contracts/auth/AxelarAuthWeighted.sol";
import { TokenDeployer } from "@axelar-network/axelar-cgp-solidity/contracts/TokenDeployer.sol";
import { Test } from "forge-std/src/Test.sol";
import { console2 } from "forge-std/src/console2.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import { Utils } from "./Utils.sol";

contract ScalarGatewayTest is Test {
  ScalarGateway public gateway;
  AxelarAuthWeighted public auth;
  TokenDeployer public tokenDeployer;

  address public owner;
  address public broadcaster;
  address[] public operators;
  mapping(address => uint256) public operatorWeights;
  uint256 constant OPERATOR_COUNT = 4;
  uint256 constant THRESHOLD = 4000;

  function setUp() public {
    // Fork mainnet
    vm.createSelectFork("mainnet");

    operators = new address[](OPERATOR_COUNT);
    uint256[] memory weights = new uint256[](OPERATOR_COUNT);

    for (uint256 i = 0; i < OPERATOR_COUNT; i++) {
      string memory operatorName = string(abi.encodePacked("operator", Strings.toString(i)));
      operators[i] = makeAddr(operatorName);
      weights[i] = 1000 * (i + 1);
      operatorWeights[operators[i]] = weights[i];
      console2.log("operator", i, operators[i]);
    }

    address[] memory newOperators = Utils.sortAddresses(operators);

    bytes memory ops = abi.encode(newOperators, weights, THRESHOLD);

    bytes[] memory recentOps = new bytes[](1);
    recentOps[0] = ops;

    auth = new AxelarAuthWeighted(new bytes[](0));
    auth.transferOperatorship(ops);

    tokenDeployer = new TokenDeployer();

    gateway = new ScalarGateway(address(auth), address(tokenDeployer));
  }

  function testDeployToken() public view {
    string memory name = "Test Token";
    uint256 random = Utils.getRandomInt(type(uint256).max, 1000);
    string memory symbol = string(abi.encodePacked(name, random));
    uint8 decimals = 18;
    uint256 cap = 1000000 * 10 ** decimals;
    uint256 limit = 1000000 * 10 ** decimals;

    bytes32 commandID = keccak256(abi.encodePacked(name, symbol, decimals, cap, limit));

    bytes32[] memory commandIDs = new bytes32[](1);
    commandIDs[0] = commandID;

    string[] memory commandNames = new string[](1);
    commandNames[0] = "deployToken";

    bytes[] memory commands = new bytes[](1);
    commands[0] = Utils.getDeployCommand(name, symbol, decimals, cap, address(0), limit);

    // Now pass these arrays to the function
    bytes memory data = Utils.buildCommandBatch(commandIDs, commandNames, commands);


    
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
