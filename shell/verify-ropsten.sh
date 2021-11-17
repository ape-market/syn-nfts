#!/usr/bin/env bash

# SynNFT
npx hardhat verify --show-stack-traces \
  --network ropsten \
  0xAbE1e28c9Cc5ad757d85888C1b59306CAFcBC737 \
  "Syn Blueprint" "SYNBP" "https://blueprint.syn.city/metadata/"

# SynNFTFactory
npx hardhat verify --show-stack-traces \
  --network ropsten \
  0xcd3772437285259D797eE8b46f9f9A7383513d33
