// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import { BaseScript } from "./Base.s.sol";
import { ERC20CrossChain } from "../src/ERC20CrossChain.sol";
import { console2 } from "forge-std/src/console2.sol";
import { TransparentUpgradeableProxy } from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import { ProxyAdmin } from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

contract DeployERC20CrossChain is BaseScript {
  function run(
    address gateway,
    address gasService,
    uint8 decimals,
    string memory name,
    string memory symbol
  ) public broadcast returns (ERC20CrossChain) {
    // Deploy implementation
    ERC20CrossChain implementation = new ERC20CrossChain(gateway, gasService, decimals);
    console2.log("Implementation deployed at:", address(implementation));

    // Deploy ProxyAdmin
    ProxyAdmin proxyAdmin = new ProxyAdmin();
    console2.log("ProxyAdmin deployed at:", address(proxyAdmin));

    // Encode initialization data
    bytes memory initData = abi.encodeWithSelector(implementation.setup.selector, abi.encode(name, symbol));

    // Deploy proxy
    TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
      address(implementation),
      address(proxyAdmin),
      initData
    );

    console2.log("Proxy deployed at:", address(proxy));

    return ERC20CrossChain(address(proxy));
  }
}
