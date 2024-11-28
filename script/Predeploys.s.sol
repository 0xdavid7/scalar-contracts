// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

/// @title Predeploys
/// @notice Contains constant addresses for contracts that are pre-deployed to the OP Stack L2 system.
library Predeploys {
    /// @notice Address of the GATEWAY predeploy.
    address internal constant GATEWAY_ADDRESS = 0xc9c5EC5975070a5CF225656e36C53e77eEa318b5;

    /// @notice Address of the Gas Services predeploy.
    address internal constant GAS_SERVICES = 0xc6D14235E3b859a3e13df81D7E7E032756671Bbc;
}
