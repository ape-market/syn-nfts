require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-etherscan");
const requireOrMock = require('require-or-mock');
// require("hardhat-gas-reporter");

let env = requireOrMock('./env.json',
    // fake example values
    {
      "privateKey": "7e36ba14d238facb478cbed5efcae784d6bac0974bec39bf7bf4f944a4a2ff80",
      "etherscanKey": "2FFVPX5HXTWGXWM7V7UN4SKSFIZPZS94ZC",
      "bscscanKey": "FB2RUP2A2XZXRWGHHI1AWMEIZTJBPDYQHI",
      "maticvigilKey": "c228e91fea28c3a5d295cac1c27642f5218d56f5",
      "infuraApiKey": "f3fec4c27b7ec91c2224181249d8a284",
      "coinMarketCapAPIKey": "ef645423-65f4-6534-b000-ecfda787655f"
    }
);

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
      url: `https://mainnet.infura.io/v3/${env.infuraApiKey}`,
      accounts: [env.privateKey]
    },
    bsc_testnet: {
      url: "https://data-seed-prebsc-1-s1.binance.org:8545",
      chainId: 97,
      gasPrice: 20000000000,
      accounts: [env.privateKey]
    },
    bsc: {
      url: "https://bsc-dataseed.binance.org/",
      chainId: 56,
      gasPrice: 20000000000,
      accounts: [env.privateKey]
    },
    mumbai: {
      url: "https://rpc-mumbai.matic.today/",
      chainId: 80001,
      gasPrice: 20000000000,
      accounts: [env.privateKey]
    },
    matic: {
      url: `https://rpc-mainnet.maticvigil.com/v1/${env.maticvigilKey}`,
      chainId: 137,
      gasPrice: 20000000000,
      accounts: [env.privateKey]
    },
  },
  etherscan: {
    apiKey: env.etherscanKey
    // apiKey: env.bscscanKey
  },
  gasReporter: {
    currency: 'USD',
    coinmarketcap: env.coinMarketCapAPIKey
  }
};

