require('dotenv').config()
require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-etherscan");
// const requireOrMock = require('require-or-mock');

if (process.env.GAS_REPORT === 'yes') {
  require("hardhat-gas-reporter");
}

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async () => {
  const accounts = await ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: {
    version: '0.8.0',
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  networks: {
    hardhat: {
      blockGasLimit: 10000000,
    },
    localhost: {
      url: "http://localhost:8545"
    },
    ethereum: {
      url: `https://mainnet.infura.io/v3/${process.env.INFURA_API_KEY || ''}`,
      accounts: [process.env.OWNER_PRIVATE_KEY]
    },
    ropsten: {
      url: `https://ropsten.infura.io/v3/${process.env.INFURA_API_KEY || ''}`,
      accounts: [process.env.OWNER_PRIVATE_KEY]
    }
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_KEY
  },
  gasReporter: {
    currency: 'USD',
    coinmarketcap: process.env.COIN_MARKET_CAP_API_KEY
  }
};

