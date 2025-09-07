import { ethers } from 'hardhat';
import dotenv from 'dotenv';

dotenv.config();

const contractName = 'USDOPoRAssetsTracking';

// Validate required environment variables
const validateEnv = () => {
  const admin = process.env.ADMIN_ADDRESS;
  const operator = process.env.OPERATOR_ADDRESS;

  if (!admin) {
    throw new Error('ADMIN_ADDRESS is not defined in environment variables');
  }
  if (!operator) {
    throw new Error('OPERATOR_ADDRESS is not defined in environment variables');
  }

  return { admin, operator };
};

// Deploy with terminal
const deploy = async () => {
  try {
    const [deployer] = await ethers.getSigners();
    const { admin, operator } = validateEnv();

    console.log('Deployer:', await deployer.getAddress());
    console.log('Account balance:', ethers.utils.formatEther(await deployer.getBalance()));
    console.log('Admin address:', admin);
    console.log('Operator address:', operator);

    const contractFactory = await ethers.getContractFactory(contractName);
    const contract = await contractFactory.deploy(admin, operator);
    const res = await contract.deployed();

    console.log(`Contract ${contractName} deployed to: ${res.address}`);
    console.log('Transaction hash:', res.deployTransaction.hash);
  } catch (error) {
    console.error('Deployment failed:', error);
    throw error;
  }
};

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
deploy()
  .then(() => process.exit(0))
  .catch(error => {
    console.error('Deployment script failed:', error);
    process.exit(1);
  });
