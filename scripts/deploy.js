// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");

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
  const synNft = await SynNFT.deploy()
  await synNft.deployed()
  // EverDragons2Manager = await ethers.getContractFactory("EverDragons2Manager")
  // everDragons2Manager = await EverDragons2Manager.deploy(everDragons2.address)
  // await everDragons2Manager.deployed()
  // everDragons2.setManager(everDragons2Manager.address)

  console.log("ERC721Manageable deployed to:", synNft.address);
  // console.log("EverDragons2Manager deployed to:", everDragons2Manager.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });

