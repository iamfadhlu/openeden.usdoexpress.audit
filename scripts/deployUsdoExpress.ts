import { ethers, platform, upgrades } from 'hardhat';
import config from 'config';

// testnet
// export NODE_ENV=sepolia
// npx hardhat run scripts/deployUsdoExpress.ts --network sepolia

// export NODE_ENV=base_sepolia
// npx hardhat run scripts/deployUsdoExpress.ts --network base_sepolia

// export NODE_ENV=arbi_sepolia
// npx hardhat run scripts/deployUsdoExpress.ts --network arbi_sepolia

// mainnet
// export NODE_ENV=mainnet
// npx hardhat run scripts/deployUsdoExpress.ts --network mainnet

// export NODE_ENV=base_mainnet
// npx hardhat run scripts/deployUsdoExpress.ts --network base_mainnet

// export NODE_ENV=arbi_mainnet
// npx hardhat run scripts/deployUsdoExpress.ts --network arbi_mainnet

const contractName = 'USDOExpress';
const salt = '1337e';

const {
  USDO_ADDRESS,
  USDC_ADDRESS,
  TBILL_ADDRESS,
  BUIDL_ADDRESS,
  BUIDL_REDEMPTION,
  TREASURY,
  BUIDL_TREASURY,
  FEE_TO,
  ADMIN_ADDRESS,
} = config.get('ADDRESS') as {
  USDO_ADDRESS: string;
  USDC_ADDRESS: string;
  TBILL_ADDRESS: string;
  BUIDL_ADDRESS: string;
  BUIDL_REDEMPTION: string;
  TREASURY: string;
  BUIDL_TREASURY: string;
  FEE_TO: string;
  ADMIN_ADDRESS: string;
};

const {
  TOTAL_SUPPLY_CAP,
  FIRST_DEPOSIT_AMOUNT,
  MINT_MINIMUM,
  MINT_LIMIT,
  MINT_DURATION,
  REDEEM_MINIMUM,
  REDEEM_LIMIT,
  REDEEM_DURATION,
  MIN_FEE,
  REDEEM_FEE,
} = config.get('LIMITS') as {
  TOTAL_SUPPLY_CAP: string;
  FIRST_DEPOSIT_AMOUNT: string;
  MINT_MINIMUM: string;
  MINT_LIMIT: string;
  MINT_DURATION: string;
  REDEEM_MINIMUM: string;
  REDEEM_LIMIT: string;
  REDEEM_DURATION: string;
  MIN_FEE: string;
  REDEEM_FEE: string;
};

const parseNumericString = (value: string): string => value.replace(/_/g, '');

const limiterConfig = {
  totalSupplyCap: ethers.utils.parseUnits(parseNumericString(TOTAL_SUPPLY_CAP), 18),
  mintMinimum: ethers.utils.parseUnits(parseNumericString(MINT_MINIMUM), 6),
  mintLimit: ethers.utils.parseUnits(parseNumericString(MINT_LIMIT), 18),
  mintDuration: parseNumericString(MINT_DURATION),
  redeemMinimum: ethers.utils.parseUnits(parseNumericString(REDEEM_MINIMUM), 18),
  redeemLimit: ethers.utils.parseUnits(parseNumericString(REDEEM_LIMIT), 18),
  redeemDuration: parseNumericString(REDEEM_DURATION),
  firstDepositAmount: ethers.utils.parseUnits(parseNumericString(FIRST_DEPOSIT_AMOUNT), 6),
};

const initializerArgs = [
  USDO_ADDRESS,
  USDC_ADDRESS,
  TBILL_ADDRESS,
  BUIDL_ADDRESS,
  BUIDL_REDEMPTION,
  TREASURY,
  BUIDL_TREASURY,
  FEE_TO,
  ADMIN_ADDRESS,
  limiterConfig,
];

console.log('Deploying contract with the following arguments:', initializerArgs);

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

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
deploy()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
