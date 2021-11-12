#!/usr/bin/env bash

# SynNFT
npx hardhat verify --show-stack-traces \
  --network ropsten \
  0x79cDB35f2b4B99394f77b2F7ea0cB1887c2D06b5 \
  "Syn Blueprint" "SYNBP" "https://blueprint.syn.city/metadata/"

# SynNFTFactory
npx hardhat verify --show-stack-traces \
  --network ropsten \
  0x04B145d32587B2682b093aa0D109de8e751cf50B \
  0x34923658675B99B2DB634cB2BC0cA8d25EdEC743 0x34923658675B99B2DB634cB2BC0cA8d25EdEC743 100
