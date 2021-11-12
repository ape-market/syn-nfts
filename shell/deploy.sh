#!/usr/bin/env bash
# must be run from the root

VALIDATOR=$2 TREASURY=$3 REMAINING_FREE_TOKENS=$4 npx hardhat run scripts/deploy.js --network $1
