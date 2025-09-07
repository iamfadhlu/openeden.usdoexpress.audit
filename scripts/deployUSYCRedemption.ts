import { ethers, upgrades } from 'hardhat';

// export NODE_ENV=sepolia
// npx hardhat run scripts/deployUSYCRedemption.ts --network sepolia

// export NODE_ENV=base_sepolia
// npx hardhat run scripts/deployUSYCRedemption.ts --network base_sepolia

// If DEPLOY_MOCKS is true, these will be set after deployment
// If false, you need to provide existing contract addresses
const usycAddress = '0x38D3A3f8717F4DB1CcB4Ad7D8C755919440848A3';
const usdcAddress = '0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238';
const helperAddress = '0xbb0524426bc1d13dAB721DB69D86374FC6BaCDba';
const callerAddress = '0xE8191108261f3234f1C2acA52a0D5C11795Aef9E';
const usycTreasury = '0xC4109e427A149239e6C1E35Bb2eCD0015B6500B8';

const contractName = 'UsycRedemption';
// const salt = '1337';

// const contractName = 'cUSDO';
// const initializerArgs = [USDO_ADDRESS, ADMIN_ADDRESS];
// const salt = '1337w';

// Deploy with terminal
// eslint-disable-next-line @typescript-eslint/no-unused-vars
const deploy = async () => {
  const [deployer] = await ethers.getSigners();

  console.log('Deployer: %s', await deployer.getAddress());
  console.log('Account balance: %s', ethers.utils.formatEther(await deployer.getBalance()));

  // Validate addresses
  console.log('\nValidating addresses...');
  console.log('USYC Address:', usycAddress);
  console.log('USDC Address:', usdcAddress);
  console.log('Helper Address:', helperAddress);
  console.log('Caller Address:', callerAddress);
  console.log('USYCTreasury Address:', usycTreasury);

  console.log('\nDeploying UsycRedemption contract...');
  const contractFactory = await ethers.getContractFactory(contractName);

  // Prepare initializer arguments
  const initializerArgs = [usycAddress, usdcAddress, helperAddress, callerAddress, usycTreasury];

  try {
    const contract = await upgrades.deployProxy(contractFactory, initializerArgs, {
      initializer: 'initialize',
      kind: 'uups',
      // salt,
      verifySourceCode: true,
    });

    await contract.deployed();

    console.log('✅ Contract deployed successfully!');
    console.log('Contract address: %s', contract.address);

    // Get implementation address
    const implementationAddress = await upgrades.erc1967.getImplementationAddress(contract.address);
    console.log('Implementation address: %s', implementationAddress);

    // Verify the contract was initialized correctly
    console.log('\nVerifying contract state...');
    const usyc = await contract.usyc();
    const usdc = await contract.usdc();
    const helper = await contract.helper();
    const caller = await contract.caller();
    const treasury = await contract.usycTreasury();

    console.log('USYC token:', usyc);
    console.log('USDC token:', usdc);
    console.log('Helper:', helper);
    console.log('Caller:', caller);
    console.log('Treasury:', treasury);
  } catch (error) {
    console.error('❌ Deployment failed:', error);
    throw error;
  }
};

deploy()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
