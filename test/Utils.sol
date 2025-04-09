// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

library Utils {
  bytes private constant CHARACTERS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";

  function getRandomInt(uint256 max, uint256 seed) internal pure returns (uint256) {
    return uint256(keccak256(abi.encodePacked(seed))) % max;
  }

  function getRandomBytes32() internal view returns (bytes32) {
    uint256 max = type(uint256).max;
    uint256 rand = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty))) % max;
    return bytes32(rand);
  }

  function getRandomString(uint256 length, uint256 seed) internal pure returns (string memory) {
    bytes memory result = new bytes(length);
    uint256 charactersLength = CHARACTERS.length;

    for (uint256 i = 0; i < length; i++) {
      uint256 rand = uint256(keccak256(abi.encodePacked(seed, i))) % charactersLength;
      result[i] = CHARACTERS[rand];
    }

    return string(result);
  }

  function sortOperators(
    address[] memory addresses,
    uint256[] memory keys,
    uint256[] memory weights
  ) public pure returns (address[] memory, uint256[] memory, uint256[] memory) {
    uint256 length = addresses.length;
    for (uint256 i = 0; i < length - 1; i++) {
      uint256 minIndex = i;

      for (uint256 j = i + 1; j < length; j++) {
        if (uint160(addresses[j]) < uint160(addresses[minIndex])) {
          minIndex = j;
        }
      }

      if (minIndex != i) {
        address temp = addresses[i];
        addresses[i] = addresses[minIndex];
        addresses[minIndex] = temp;

        uint256 tempKey = keys[i];
        keys[i] = keys[minIndex];
        keys[minIndex] = tempKey;

        uint256 tempWeight = weights[i];
        weights[i] = weights[minIndex];
        weights[minIndex] = tempWeight;
      }
    }
    return (addresses, keys, weights);
  }

  function buildCommandBatch(
    bytes32[] calldata commandIDs,
    string[] calldata commandNames,
    bytes[] calldata commands
  ) public view returns (bytes memory) {
    return abi.encode(block.chainid, commandIDs, commandNames, commands);
  }

  function setupTokenDeployment(
    string memory name
  ) public pure returns (string memory symbol, uint8 decimals, uint256 cap, uint256 limit, bytes32 commandID) {
    uint256 random = Utils.getRandomInt(type(uint256).max, 1000);
    symbol = string(abi.encodePacked(name, random));
    decimals = 18;
    cap = 1_000_000 * 10 ** decimals;
    limit = cap;
    commandID = keccak256(abi.encodePacked(name, symbol, decimals, cap, limit));
  }

  function prepareCommands(
    bytes32 commandID,
    string memory name,
    bytes memory command
  ) public pure returns (bytes32[] memory, string[] memory, bytes[] memory) {
    bytes32[] memory commandIDs = new bytes32[](1);
    commandIDs[0] = commandID;
    string[] memory commandNames = new string[](1);
    commandNames[0] = name;
    bytes[] memory commands = new bytes[](1);
    commands[0] = command;
    return (commandIDs, commandNames, commands);
  }
}
