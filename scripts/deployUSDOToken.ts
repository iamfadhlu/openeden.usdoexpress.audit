import { ethers, upgrades } from 'hardhat';
import config from 'config';

// export NODE_ENV=sepolia
// npx hardhat run scripts/deployUSDO.ts --network sepolia

// export NODE_ENV=base_sepolia
// npx hardhat run scripts/deployUSDO.ts --network base_sepolia

const { ADMIN_ADDRESS, USDO_ADDRESS } = config.get('ADDRESS') as {
  USDO_ADDRESS: string;
  ADMIN_ADDRESS: string;
};
const contractName = 'USDO';
const initializerArgs = ['OpenEden Open Dollar', 'USDO', ADMIN_ADDRESS];
const salt = '1337';

// const contractName = 'cUSDO';
// const initializerArgs = [USDO_ADDRESS, ADMIN_ADDRESS];
// const salt = '1337w';

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

// Upgrade with terminal
// eslint-disable-next-line @typescript-eslint/no-unused-vars
const upgradeUSDO = async () => {
  console.log('Upgrading USDO contract... %s', USDO_ADDRESS);

  const newContract = await ethers.getContractFactory(contractName);
  await upgrades.upgradeProxy(USDO_ADDRESS || '', newContract);

  console.log('USDO Contract upgraded!');
};

deploy()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
