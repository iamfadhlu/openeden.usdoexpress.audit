import { ethers, platform, upgrades } from 'hardhat';
import dotenv from 'dotenv';

dotenv.config();

const contractName = 'USDOExpressV2';

// Deploy with terminal
// eslint-disable-next-line @typescript-eslint/no-unused-vars
const deploy = async () => {
  const [deployer] = await ethers.getSigners();

  console.log('Deployer: %s', await deployer.getAddress());
  console.log('Account balance: %s', ethers.utils.formatEther(await deployer.getBalance()));

  const contractFactory = await ethers.getContractFactory(contractName);
  const contract = await contractFactory.deploy();
  const res = await contract.deployed();
  console.log(`Contract ${contractName} deployed to: ${res.address}`);
};

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
deploy()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
