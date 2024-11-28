// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

import { Script } from "forge-std/src/Script.sol";

abstract contract BaseScript is Script {
    address internal broadcaster;

    constructor() {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        broadcaster = vm.addr(deployerPrivateKey);
    }

    modifier broadcast() {
        vm.startBroadcast(broadcaster);
        _;
        vm.stopBroadcast();
    }
}
