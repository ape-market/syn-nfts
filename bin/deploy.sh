#!/usr/bin/env bash
# must be run from the root

#while getopts "r:o:" opt; do
#	  case $opt in
#		s)
#		  SAVE=1
#		  ;;
#		v)
#		  VALIDATOR=$OPTARG
#		  ;;
#		t)
#		  TREASURY=$OPTARG
#		  ;;
#		\?)
#		  help
#		  exit 1
#		  ;;
#	  esac
#	done

if [[ "$2" == "--save" ]]; then
  SAVE_DEPLOYED_ADDRESSES=1 npx hardhat run scripts/deploy.js --network $1
else
  npx hardhat run scripts/deploy.js --network $1
fi
