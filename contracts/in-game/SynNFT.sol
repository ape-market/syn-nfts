// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Author: Francesco Sullo <francesco@sullo.co>
// Forked from EverDragons2(.com)'s code

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

//import "hardhat/console.sol";

contract SynNFT is ERC721, ERC721Enumerable, Ownable {
  using Address for address;
  using Counters for Counters.Counter;

  event FactorySet(address factory);

  address public factory;
  Counters.Counter private _tokenIdTracker;

  string private _baseTokenURI;
  uint256 private _mintStatus = 1;

  modifier onlyFactory() {
    require(factory != address(0) && _msgSender() == factory, "forbidden");
    _;
  }

  constructor(
    string memory name,
    string memory symbol,
    string memory baseTokenURI
  ) ERC721(name, symbol) {
    _baseTokenURI = baseTokenURI;
    _tokenIdTracker.increment(); // < starts from 1
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal override(ERC721, ERC721Enumerable) {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  // Initially, the factory manages the minting
  // Later, it will be replaced by the game's contract
  function setFactory(address factory_) external onlyOwner {
    require(factory_ != address(0), "factory cannot be 0x0");
    factory = factory_;
  }

  function safeMint(address to, uint256 quantity) external onlyFactory {
    require(to != address(0), "recipient cannot be 0x0");
    for (uint256 i = 0; i < quantity; i++) {
      _safeMint(to, _tokenIdTracker.current());
      _tokenIdTracker.increment();
    }
  }

  function burn(uint256 tokenId) public virtual onlyFactory {
    _burn(tokenId);
  }

  function nextTokenId() external view returns (uint256) {
    return _tokenIdTracker.current();
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function updateBaseURI(string memory baseTokenURI) external onlyOwner {
    _baseTokenURI = baseTokenURI;
  }
}
