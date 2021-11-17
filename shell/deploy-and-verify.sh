#!/usr/bin/env bash

rm -rf artifacts
rm -rf cache

npx hardhat compile

VALIDATOR=0x34923658675B99B2DB634cB2BC0cA8d25EdEC743 TREASURY=0x34923658675B99B2DB634cB2BC0cA8d25EdEC743 REMAINING_FREE_TOKENS=100 npx hardhat run scripts/deploy.js --network $1

SynNFTAddress=`cat tmp/SynNFTAddress`
SynNFTFactoryAddress=`cat tmp/SynNFTFactoryAddress`

# SynNFT
npx hardhat verify --show-stack-traces \
  --network $1 \
  $SynNFTAddress \
  "Syn Blueprint" "SYNBP" "https://blueprint.syn.city/metadata/"

# SynNFTFactory
npx hardhat verify --show-stack-traces \
  --network $1 \
  $SynNFTFactoryAddress
