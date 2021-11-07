// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/presets/ERC721PresetMinterPauserAutoId.sol";

import "./IERC721Manageable.sol";

//import "hardhat/console.sol";

contract ERC721Manageable is ERC721PresetMinterPauserAutoId {

  constructor(
    string memory name,
    string memory symbol,
    string memory baseTokenURI
  ) ERC721PresetMinterPauserAutoId(name, symbol, baseTokenURI) {}
}
