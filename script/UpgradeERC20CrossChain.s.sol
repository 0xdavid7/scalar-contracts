// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import { BaseScript } from "./Base.s.sol";
import { ERC20CrossChain } from "../src/ERC20CrossChain.sol";
import { console2 } from "forge-std/src/console2.sol";
import { ProxyAdmin } from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import { ITransparentUpgradeableProxy } from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract UpgradeERC20CrossChain is BaseScript {
    function run(
        address proxyAddress,
        address proxyAdminAddress,
        address gateway,
        address gasService,
        uint8 decimals
    )
        public
        broadcast
        returns (ERC20CrossChain)
    {
        // Deploy new implementation
        ERC20CrossChain newImplementation = new ERC20CrossChain(gateway, gasService, decimals);
        console2.log("New implementation deployed at:", address(newImplementation));

        // Get ProxyAdmin instance
        ProxyAdmin proxyAdmin = ProxyAdmin(proxyAdminAddress);

        // Upgrade proxy to new implementation
        proxyAdmin.upgrade(ITransparentUpgradeableProxy((proxyAddress)), address(newImplementation));

        console2.log("Proxy upgraded to new implementation");

        return ERC20CrossChain(proxyAddress);
    }
}
