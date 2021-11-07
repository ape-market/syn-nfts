// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Author: Francesco Sullo <francesco@sullo.co>
// Forked from EverDragons2(.com)'s code

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface ISynNFT {
  function safeMint(address to, uint256 quantity) external;

  function symbol() external returns (string memory);
}

import "hardhat/console.sol";

contract SynNFTFactory is Ownable {
  using ECDSA for bytes32;
  using SafeMath for uint256;

  event NFTSet(string nftSymbol, address nftAddress);
  event ValidatorSet(address validator);
  event TreasurySet(address treasury);

  uint256 public treasuryBalance;
  uint256 public withdrawnAmount;
  uint256 public limit;

  address public validator;
  address public treasury;

  mapping(bytes32 => uint8) public usedCodes;

  // 1 word of storage in total
  struct NFTConf {
    ISynNFT nft;
    uint256 price;
    uint maxAllocation;
    bool started;
    bool paused;
  }

  // string is the keccak256(NFT's symbol)
  mapping(bytes32 => NFTConf) public nftConf;

  constructor(address validator_, address treasury_) {
    setValidator(validator_);
    setTreasury(treasury_);
  }

  function setValidator(address validator_) public onlyOwner {
    require(validator_ != address(0), "validator cannot be 0x0");
    validator = validator_;
  }

  function setTreasury(address treasury_) public onlyOwner {
    require(treasury_ != address(0), "treasury cannot be 0x0");
    treasury = treasury_;
  }

  function getNftConf(bytes32 nftId) external view returns (NFTConf memory) {
    return nftConf[nftId];
  }

  // it implicitly starts the sale at the first call
  function startAndPauseUnpauseSale(
    bytes32 nftId,
    bool paused
  ) external {
    NFTConf memory conf = nftConf[nftId];
    conf.started = true;
    conf.paused = paused;
    nftConf[nftId] = conf;
  }

  function init(
    address nftAddress,
    uint256 tokenPrice,
    uint maxAllocation
  ) external onlyOwner {
    ISynNFT synNFT = ISynNFT(nftAddress);
    string memory symbol = synNFT.symbol();
    require(bytes(symbol).length > 0, "NFT not found");
    bytes32 nftId = keccak256(abi.encodePacked(symbol));
    nftConf[nftId] = NFTConf({nft: synNFT, price: tokenPrice, maxAllocation: maxAllocation, started: false, paused: false});
    emit NFTSet(symbol, nftAddress);
  }

  function claimFreeTokens(
    bytes32 nftId,
    uint256 quantity,
    bytes32 authCode,
    bytes memory signature
  ) public {
    // parameters are validated during the off-chain validation
    require(usedCodes[authCode] == 0, "authCode already used");
    require(isSignedByValidator(encodeForSignature(_msgSender(), nftId, quantity, authCode), signature), "invalid signature");
    NFTConf memory conf = nftConf[nftId];
    conf.nft.safeMint(_msgSender(), quantity);
    usedCodes[authCode] = 1;
  }

  function buyDiscountedTokens(
    bytes32 nftId,
    uint256 quantity,
    bytes32 authCode,
    uint256 discountedPrice,
    bytes memory signature
  ) external payable {
    // parameters are validated during the off-chain validation
    NFTConf memory conf = nftConf[nftId];
    require(conf.started, "public sale not started yet");
    require(!conf.paused, "public sale has been paused");
    require(usedCodes[authCode] == 0, "authCode already used");
    require(
      isSignedByValidator(encodeForSignature(_msgSender(), nftId, quantity, authCode, discountedPrice), signature),
      "invalid signature"
    );
    require(msg.value >= discountedPrice.mul(quantity), "insufficient payment");
    treasuryBalance += msg.value;
    conf.nft.safeMint(_msgSender(), quantity);
    usedCodes[authCode] = 1;
  }

  function giveawayTokens(
    bytes32 nftId,
    address[] memory recipients,
    uint256[] memory quantities
  ) external onlyOwner {
    require(recipients.length == quantities.length, "inconsistent lengths");
    NFTConf memory conf = nftConf[nftId];
    for (uint256 i = 0; i < recipients.length; i++) {
      conf.nft.safeMint(recipients[i], quantities[i]);
    }
  }

  function buyTokens(bytes32 nftId, uint256 quantity) public payable {
    NFTConf memory conf = nftConf[nftId];
    require(conf.started, "public sale not started yet");
    require(!conf.paused, "public sale has been paused");
    require(quantity <= conf.maxAllocation, "quantity is more than max allocation");
    require(msg.value >= conf.price.mul(quantity), "insufficient payment");
    treasuryBalance += msg.value;
    conf.nft.safeMint(_msgSender(), quantity);
  }

  // cryptography

  function isSignedByValidator(bytes32 _hash, bytes memory _signature) public view returns (bool) {
    return validator == ECDSA.recover(_hash, _signature);
  }

  function encodeForSignature(
    address addr,
    bytes32 nftId,
    uint256 quantity,
    bytes32 authCode
  ) public pure returns (bytes32) {
    return
      keccak256(
        abi.encodePacked(
          "\x19\x01", // EIP-191
          addr,
          nftId,
          quantity,
          authCode
        )
      );
  }

  function encodeForSignature(
    address addr,
    bytes32 nftId,
    uint256 quantity,
    bytes32 authCode,
    uint256 discountedPrice
  ) public pure returns (bytes32) {
    return
      keccak256(
        abi.encodePacked(
          "\x19\x01", // EIP-191
          addr,
          nftId,
          quantity,
          authCode,
          discountedPrice
        )
      );
  }

  // withdraw

  function claimEarnings(uint256 amount) external {
    require(_msgSender() == treasury, "not the treasury");
    uint256 available = treasuryBalance.sub(withdrawnAmount);
    require(amount <= available, "Insufficient funds");
    withdrawnAmount = withdrawnAmount.add(amount);
    (bool success, ) = _msgSender().call{value: amount}("");
    require(success);
  }
}
