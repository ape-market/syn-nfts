// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");
const fs = require('fs-extra')
const path = require('path')
const ethers = hre.ethers

async function currentChainId() {
  return (await ethers.provider.getNetwork()).chainId
}

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  const [deployer] = await ethers.getSigners();

  console.log(
      "Deploying contracts with the account:",
      deployer.address
  );

  console.log("Account balance:", (await deployer.getBalance()).toString());

  const SynNFT = await ethers.getContractFactory("SynNFT")
  const synNft = await SynNFT.deploy('Syn Blueprint', 'SYNBP', 'https://blueprint.syn.city/metadata/')
  await synNft.deployed()
  const SynNFTFactory = await ethers.getContractFactory("SynNFTFactory")
  const synNFTFactory = await SynNFTFactory.deploy()
  await synNFTFactory.deployed()
  await synNFTFactory.setValidatorAndTreasury(process.env.VALIDATOR, process.env.TREASURY)
  synNft.setFactory(synNFTFactory.address)

  const addresses = {
    SynNFT: synNft.address,
    SynNFTFactory: synNFTFactory.address,
  }

  const result= {}
  result[await currentChainId()] = addresses

  console.log(result)

  await saveAddresses(result, Object.keys(addresses))

}

async function saveAddresses(result, addresses) {
  const output = path.resolve(__dirname, '../export/deployed.json')
  await fs.ensureDir(path.dirname(output))
  await fs.writeFile(output, JSON.stringify(result, null, 2))
  await exportABIs(addresses)
}

async function exportABIs(contracts) {
  const ABIs = {
    when: (new Date).toISOString(),
    contracts: {}
  }

  for (let name of contracts) {
    let source = path.resolve(__dirname, `../artifacts/contracts/${name}.sol/${name}.json`)
    let json = require(source)
    ABIs.contracts[name] = json.abi
  }
  fs.writeFileSync(path.resolve(__dirname, '../export/ABIs.json'), JSON.stringify(ABIs, null, 2))
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });

