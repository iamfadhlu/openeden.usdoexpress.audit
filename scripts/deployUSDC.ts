import { ethers, platform, upgrades } from 'hardhat';
import dotenv from 'dotenv';

dotenv.config();

const deploy = async () => {
  const [deployer] = await ethers.getSigners();

  console.log('Deployer: %s', await deployer.getAddress());
  console.log('Account balance: %s', ethers.utils.formatEther(await deployer.getBalance()));

  const contractFactory = await ethers.getContractFactory('MockUSDC');
  const contract = await contractFactory.deploy();
  await contract.deployed();

  console.log('Contract address: %s', contract.address);
};

deploy()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
