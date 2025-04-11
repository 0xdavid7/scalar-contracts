// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

import { Test } from "forge-std/src/Test.sol";
import { ScalarGateway } from "../src/ScalarGateway.sol";
import { AxelarAuthWeighted } from "@axelar-network/axelar-cgp-solidity/contracts/auth/AxelarAuthWeighted.sol";
import { TokenDeployer } from "@axelar-network/axelar-cgp-solidity/contracts/TokenDeployer.sol";
import { Test } from "forge-std/src/Test.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import { ECDSA } from "@axelar-network/axelar-cgp-solidity/contracts/ECDSA.sol";
import { Vm } from "forge-std/src/Vm.sol";

import { Utils } from "./Utils.sol";
import { console2 } from "forge-std/src/console2.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { BurnableMintableCappedERC20 } from "@axelar-network/axelar-cgp-solidity/contracts/BurnableMintableCappedERC20.sol";

contract ScalarGatewayTest is Test {
  ScalarGateway public gateway;
  AxelarAuthWeighted public auth;
  TokenDeployer public tokenDeployer;

  address public owner;
  address public broadcaster;
  address[] public operators;
  uint256[] public operatorWeights;
  uint256[] operatorPrivKeys;
  uint256 constant OPERATOR_COUNT = 4;
  uint256 constant THRESHOLD = 4000;

  function setUp() public {
    // Fork mainnet
    vm.createSelectFork("mainnet");

    owner = makeAddr("owner");

    operators = new address[](OPERATOR_COUNT);
    operatorWeights = new uint256[](OPERATOR_COUNT);
    operatorPrivKeys = new uint256[](OPERATOR_COUNT);
    for (uint256 i = 0; i < OPERATOR_COUNT; i++) {
      string memory operatorName = string(abi.encodePacked("operator", Strings.toString(i)));
      (operators[i], operatorPrivKeys[i]) = makeAddrAndKey(operatorName);
      operatorWeights[i] = 1000 * (i + 1);
    }

    (operators, operatorPrivKeys, operatorWeights) = Utils.sortOperators(operators, operatorPrivKeys, operatorWeights);

    bytes memory ops = abi.encode(operators, operatorWeights, THRESHOLD);

    bytes[] memory recentOps = new bytes[](1);
    recentOps[0] = ops;

    auth = new AxelarAuthWeighted(new bytes[](0));
    auth.transferOperatorship(ops);

    tokenDeployer = new TokenDeployer();

    gateway = new ScalarGateway(address(auth), address(tokenDeployer));
  }

  function testRegisterCustodianGroup() public returns (bytes32 custodianGroupUID) {
    custodianGroupUID = _getCustodianGroupId();
    console2.log("custodianGroupUID");
    console2.logBytes32(custodianGroupUID);
    (bytes32[] memory ids, string[] memory names, bytes[] memory cmds) = Utils.prepareCommands(
      custodianGroupUID,
      "registerCustodianGroup",
      abi.encode(custodianGroupUID)
    );

    bytes memory data = Utils.buildCommandBatch(ids, names, cmds);

    bytes memory input = _getSingedWeightedExecuteInput(data);
    gateway.execute(input);

    // ScalarGateway.Session memory s = gateway.getSession(custodianGroupUID);
    // assertEq(s.sequence, 1);
    // assertEq(uint8(s.phase), uint8(ScalarGateway.Phase.Preparing));
  }

  struct TokenParams {
    string name;
    string symbol;
    uint8 decimals;
    uint256 cap;
    uint256 limit;
    bytes32 commandID;
  }

  function testDeployToken2() public returns (string memory, address tokenAddress) {
    bytes32 uid = testRegisterCustodianGroup();
    TokenParams memory params = prepareTokenParams("sBTC");

    vm.recordLogs();
    executeTokenDeployment(params, uid);
    Vm.Log[] memory logs = vm.getRecordedLogs();

    for (uint i = 0; i < logs.length; i++) {
      bytes32 eventSignature = keccak256("TokenDeployed(string,address)");
      if (logs[i].topics[0] == eventSignature) {
        (, address _tokenAddress) = abi.decode(logs[i].data, (string, address));
        tokenAddress = _tokenAddress;
        break;
      }
    }

    return (params.symbol, tokenAddress);
  }

  function prepareTokenParams(string memory name) private pure returns (TokenParams memory) {
    TokenParams memory params;
    params.name = name;
    (params.symbol, params.decimals, params.cap, params.limit, params.commandID) = Utils.setupTokenDeployment(name);
    return params;
  }

  function executeTokenDeployment(TokenParams memory params, bytes32 uid) private {
    (bytes32[] memory ids, string[] memory names, bytes[] memory cmds) = Utils.prepareCommands(
      params.commandID,
      "deployToken",
      abi.encode(params.name, params.symbol, params.decimals, params.cap, address(0), params.limit, uid)
    );

    bytes memory data = Utils.buildCommandBatch(ids, names, cmds);
    gateway.execute(_getSingedWeightedExecuteInput(data));
  }

  function testMintToken() public returns (string memory, address) {
    (string memory symbol, address addrr) = testDeployToken2();
    uint256 amount = 1000;

    bytes32 commandID = keccak256(abi.encodePacked(symbol, "mintToken"));
    (bytes32[] memory ids, string[] memory names, bytes[] memory cmds) = Utils.prepareCommands(
      commandID,
      "mintToken",
      abi.encode(symbol, owner, amount)
    );

    bytes memory data = Utils.buildCommandBatch(ids, names, cmds);
    gateway.execute(_getSingedWeightedExecuteInput(data));

    uint256 balance = IERC20(addrr).balanceOf(owner);
    assertEq(balance, amount);

    return (symbol, addrr);
  }

  function testRedeemToken() public {
    (string memory symbol, address addr) = testMintToken();
    bytes32 custodianGroupId = _getCustodianGroupId();
    uint64 seq = gateway.getSession(custodianGroupId).sequence;

    bytes32 commandID = keccak256(abi.encodePacked(symbol, "redeemToken"));
    (bytes32[] memory ids, string[] memory names, bytes[] memory cmds) = Utils.prepareCommands(
      commandID,
      "redeemToken",
      abi.encode("bitcoin", "bc12345678", new bytes(0), symbol, 1000, custodianGroupId, seq)
    );
    bytes memory data = Utils.buildCommandBatch(ids, names, cmds);
    vm.prank(owner);
    bool success = IERC20(addr).approve(address(gateway), 1000);
    assertEq(success, true);
    vm.prank(owner);
    gateway.execute(_getSingedWeightedExecuteInput(data));
  }

  function test_getSession() public {
    vm.expectRevert(ScalarGateway.NotInitializedSession.selector);
    gateway.getSession(keccak256("test"));
  }

  function testDeployTokenByDeployer() public {
    string memory symbol = "sBtc";
    string memory name = "Scalar pool";
    uint8 decimals = 8;
    uint256 cap = 0;
    bytes32 salt = keccak256(abi.encodePacked(symbol));
    console2.logBytes32(salt);
    vm.prank(address(0x14eDDfb40458C886A2d3B2B9cC5949D4d19DFA57));
    address tokenAddress = address(new BurnableMintableCappedERC20{ salt: salt }(name, symbol, decimals, cap));

    console2.log("tokenAddress", tokenAddress);
    assertEq(0xe15Ba8203cDB284caEE014e6eF53C4eE1Ac5F8E7, tokenAddress);
  }

  function _getWeightedSignaturesProof(bytes memory data) private view returns (bytes memory) {
    bytes32 ethSignedMessageHash = ECDSA.toEthSignedMessageHash(keccak256(data));

    bytes[] memory signatures = new bytes[](OPERATOR_COUNT);
    uint256 totalWeight;

    for (uint256 i = 0; i < OPERATOR_COUNT && totalWeight < THRESHOLD; i++) {
      (uint8 v, bytes32 r, bytes32 s) = vm.sign(operatorPrivKeys[i], ethSignedMessageHash);
      signatures[i] = abi.encodePacked(r, s, v);
      totalWeight += operatorWeights[i];
    }

    bytes memory proof = abi.encode(operators, operatorWeights, THRESHOLD, signatures);
    return proof;
  }

  function _getSingedWeightedExecuteInput(bytes memory data) private view returns (bytes memory) {
    bytes memory proof = _getWeightedSignaturesProof(data);
    return abi.encode(data, proof);
  }

  function _getCustodianGroupId() private pure returns (bytes32 custodianGroupUID) {
    string memory name = "Test Custodian Group";
    custodianGroupUID = keccak256(abi.encodePacked(name));
  }
}
