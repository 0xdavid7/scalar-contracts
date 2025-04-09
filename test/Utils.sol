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

  function sortAddresses(address[] memory addresses) public pure returns (address[] memory) {
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
      }
    }
    return addresses;
  }

  function buildCommandBatch(
    bytes32[] calldata commandIDs,
    string[] calldata commandNames,
    bytes[] calldata commands
  ) public view returns (bytes memory) {
    return abi.encode(block.chainid, commandIDs, commandNames, commands);
  }

  function getDeployCommand(
    string memory name,
    string memory symbol,
    uint8 decimals,
    uint256 cap,
    address tokenAddress,
    uint256 dailyMintLimit
  ) public pure returns (bytes memory command) {
    return abi.encode(name, symbol, decimals, cap, tokenAddress, dailyMintLimit);
  }
}
