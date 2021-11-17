// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Author: Francesco Sullo <francesco@sullo.co>
// Forked from EverDragons2(.com)'s code

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "hardhat/console.sol";

interface ISynNFT {
  function safeMint(address to, uint256 quantity) external;

  function symbol() external returns (string memory);

  function balanceOf(address owner) external view returns (uint256);

  function nextTokenId() external view returns (uint256);
}

contract SynNFTFactory is Ownable {
  using ECDSA for bytes32;
  using SafeMath for uint256;

  event NFTSet(address nftAddress);
  event ValidatorSet(address validator);
  event TreasurySet(address treasury);

  uint256 public withdrawnAmount;
  uint256 public limit;

  address public validator;
  address public treasury;
  address public game;

  mapping(bytes32 => uint8) public usedCodes;

  // 1 word of storage in total
  struct NFTConf {
    ISynNFT nft;
    uint256 price;
    uint8 maxAllocationPerWallet;
    uint16 remainingInitialSaleAllocation; // the initial amount of tokens for sale
    uint16 remainingReservedAllocation; // the initial amount of tokens reserved to blueprint owners. It can be 0
    bool paused;
  }

  mapping(address => NFTConf) public nftConf;

  function setValidator(address validator_) public onlyOwner {
    require(validator_ != address(0), "validator cannot be 0x0");
    validator = validator_;
  }

  function setTreasury(address treasury_) public onlyOwner {
    require(treasury_ != address(0), "treasury cannot be 0x0");
    treasury = treasury_;
  }

  function setGame(address game_) public onlyOwner {
    require(game_ != address(0), "game cannot be 0x0");
    game = game_;
  }

  function getNftConf(address nftAddress) external view returns (NFTConf memory) {
    return nftConf[nftAddress];
  }

  function init(
    address nftAddress,
    uint256 price,
    uint8 maxAllocationPerWallet,
    uint16 remainingInitialSaleAllocation,
    uint16 remainingReservedAllocation
  ) external onlyOwner {
    require(validator != address(0) && treasury != address(0), "validator and/or treasury not set, yet");
    ISynNFT synNFT = ISynNFT(nftAddress);
    nftConf[nftAddress] = NFTConf({
      nft: synNFT,
      price: price,
      maxAllocationPerWallet: maxAllocationPerWallet,
      remainingInitialSaleAllocation: remainingInitialSaleAllocation,
      remainingReservedAllocation: remainingReservedAllocation,
      paused: true
    });
    emit NFTSet(nftAddress);
  }

  function pause(address nftAddress, bool paused) external onlyOwner {
    nftConf[nftAddress].paused = paused;
  }

  function claimFreeToken(
    address nftAddress,
    bytes32 authCode,
    bytes memory signature
  ) public {
    // parameters are validated during the off-chain validation
    require(usedCodes[authCode] == 0, "authCode already used");
    require(isSignedByValidator(encodeForSignature(_msgSender(), nftAddress, authCode), signature), "invalid signature");
    NFTConf memory conf = nftConf[nftAddress];
    require(conf.remainingReservedAllocation >= 1, "no more free tokens available");
    conf.nft.safeMint(_msgSender(), 1);
    usedCodes[authCode] = 1;
    nftConf[nftAddress].remainingReservedAllocation--;
  }

  function buyDiscountedTokens(
    address nftAddress,
    uint256 quantity,
    bytes32 authCode,
    uint256 discountedPrice,
    bytes memory signature
  ) external payable {
    // parameters are validated during the off-chain validation
    NFTConf memory conf = nftConf[nftAddress];
    require(usedCodes[authCode] == 0, "authCode already used");
    require(
      conf.nft.balanceOf(_msgSender()) + quantity <= conf.remainingInitialSaleAllocation,
      "quantity exceeds max allocation"
    );
    require(
      isSignedByValidator(encodeForSignature(_msgSender(), nftAddress, quantity, authCode, discountedPrice), signature),
      "invalid signature"
    );
    require(msg.value >= discountedPrice.mul(quantity), "insufficient payment");
    conf.nft.safeMint(_msgSender(), quantity);
    usedCodes[authCode] = 1;
    nftConf[nftAddress].remainingInitialSaleAllocation -= uint16(quantity);
  }

  function giveawayTokens(
    address nftAddress,
    address[] memory recipients,
    uint256[] memory quantities
  ) external onlyOwner {
    require(recipients.length == quantities.length, "inconsistent lengths");
    NFTConf memory conf = nftConf[nftAddress];
    for (uint256 i = 0; i < recipients.length; i++) {
      conf.nft.safeMint(recipients[i], quantities[i]);
    }
  }

  function buyTokens(address nftAddress, uint256 quantity) public payable {
    NFTConf memory conf = nftConf[nftAddress];
    require(!conf.paused, "sale is either not open or has been paused");
    require(
      conf.nft.balanceOf(_msgSender()) + quantity <= conf.remainingInitialSaleAllocation,
      "quantity exceeds max allocation"
    );
    require(msg.value >= conf.price.mul(quantity), "insufficient payment");
    conf.nft.safeMint(_msgSender(), quantity);
    nftConf[nftAddress].remainingInitialSaleAllocation -= uint16(quantity);
  }

  // cryptography

  function isSignedByValidator(bytes32 _hash, bytes memory _signature) public view returns (bool) {
    return validator == ECDSA.recover(_hash, _signature);
  }

  function encodeForSignature(
    address recipient,
    address nftAddress,
    bytes32 authCode
  ) public pure returns (bytes32) {
    return
      keccak256(
        abi.encodePacked(
          "\x19\x01", // EIP-191
          recipient,
          nftAddress,
          authCode
        )
      );
  }

  function encodeForSignature(
    address recipient,
    address nftAddress,
    uint256 quantity,
    bytes32 authCode,
    uint256 discountedPrice
  ) public pure returns (bytes32) {
    return
      keccak256(
        abi.encodePacked(
          "\x19\x01", // EIP-191
          recipient,
          nftAddress,
          quantity,
          authCode,
          discountedPrice
        )
      );
  }

  // withdraw

  function withdrawProceeds(uint256 amount) external {
    require(_msgSender() == treasury, "not the treasury");
    uint256 available = address(this).balance;
    if (amount == 0) {
      amount = available;
    }
    require(amount <= available, "Insufficient funds");
    (bool success, ) = _msgSender().call{value: amount}("");
    require(success);
  }
}
