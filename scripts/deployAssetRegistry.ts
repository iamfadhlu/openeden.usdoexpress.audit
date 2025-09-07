import { ethers, upgrades } from 'hardhat';
import config from 'config';

// export NODE_ENV=sepolia
// npx hardhat run scripts/deployAssetRegistry.ts --network sepolia

// export NODE_ENV=base_sepolia
// npx hardhat run scripts/deployUSDO.ts --network base_sepolia

const { ADMIN_ADDRESS } = config.get('ADDRESS') as {
  ADMIN_ADDRESS: string;
};
const contractName = 'AssetRegistry';
const initializerArgs = [ADMIN_ADDRESS];
const salt = '1337';

// Deploy with terminal
// eslint-disable-next-line @typescript-eslint/no-unused-vars
const deploy = async () => {
  const [deployer] = await ethers.getSigners();

  console.log('Deployer: %s', await deployer.getAddress());
  console.log('Account balance: %s', ethers.utils.formatEther(await deployer.getBalance()));

  const contractFactory = await ethers.getContractFactory(contractName);
  const contract = await upgrades.deployProxy(contractFactory, initializerArgs, {
    initializer: 'initialize',
    kind: 'uups',
    salt,
    verifySourceCode: true,
  });

  //const contract = await contractFactory.deploy();
  await contract.deployed();

  console.log('Contract address: %s', contract.address);
};

deploy()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
