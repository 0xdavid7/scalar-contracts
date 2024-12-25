// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IAxelarGateway } from "@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGateway.sol";
import { IAxelarGasService } from "@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGasService.sol";
import { ERC20 } from "@axelar-network/axelar-gmp-sdk-solidity/contracts/test/token/ERC20.sol";
import { AxelarExecutable } from "@axelar-network/axelar-gmp-sdk-solidity/contracts/executable/AxelarExecutable.sol";
import { Upgradable } from "@axelar-network/axelar-gmp-sdk-solidity/contracts/upgradable/Upgradable.sol";
import { StringToAddress, AddressToString } from "@axelar-network/axelar-gmp-sdk-solidity/contracts/libs/AddressString.sol";
import { IERC20CrossChain } from "./interfaces/IERC20CrossChain.sol";

contract ERC20CrossChain is AxelarExecutable, ERC20, Upgradable, IERC20CrossChain {
  using StringToAddress for string;
  using AddressToString for address;

  error AlreadyInitialized();

  event FalseSender(string sourceChain, string sourceAddress);

  event TransferRemote(string destinationChain, address destinationContractAddress, address sender, uint256 amount);

  IAxelarGasService public immutable gasService;

  constructor(
    address gateway_,
    address gasReceiver_,
    uint8 decimals_
  ) AxelarExecutable(gateway_) ERC20("", "", decimals_) {
    gasService = IAxelarGasService(gasReceiver_);
  }

  function _setup(bytes calldata params) internal override {
    (string memory name_, string memory symbol_) = abi.decode(params, (string, string));
    if (bytes(name).length != 0) revert AlreadyInitialized();
    name = name_;
    symbol = symbol_;
  }

  // TODO: Remove this. This is for testing.
  function faucet(uint256 amount) external {
    _mint(msg.sender, amount);
  }

  function transferRemote(
    string calldata destinationChain,
    address destinationContractAddress,
    uint256 amount,
    bytes calldata encodedMetadata
  ) public payable override {
    require(msg.value > 0, "Gas payment is required");
    require(amount > 0, "Amount must be greater than 0");

    _burn(msg.sender, amount);

    bytes memory payload = abi.encode(msg.sender, address(this), symbol, encodedMetadata);

    string memory stringAddress = destinationContractAddress.toString();

    gasService.payNativeGasForContractCall{ value: msg.value }(
      address(this),
      destinationChain,
      stringAddress,
      payload,
      msg.sender
    );

    gateway.callContract(destinationChain, stringAddress, payload);

    emit TransferRemote(destinationChain, destinationContractAddress, msg.sender, amount);
  }

  function _execute(
    string calldata _sourceChain,
    string calldata _sourceAddress,
    bytes calldata _payload
  ) internal override {
    if (_sourceAddress.toAddress() != address(this)) {
      emit FalseSender(_sourceChain, _sourceAddress);
      return;
    }
    (address to, uint256 amount) = abi.decode(_payload, (address, uint256));
    _mint(to, amount);
  }

  function contractId() external pure returns (bytes32) {
    return keccak256("scalar-erc20-crosschain");
  }
}
