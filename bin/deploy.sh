#!/usr/bin/env bash
# must be run from the root

VALIDATOR=$2 TREASURY=$3 npx hardhat run scripts/deploy.js --network $1
