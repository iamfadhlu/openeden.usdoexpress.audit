# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

```bash
# Core development
npm test                    # Run full test suite
npm run test:specific      # Run specific test file
npm run coverage           # Generate coverage report
npm run compile            # Compile all contracts
npm run lint               # Lint JS/TS and Solidity code

# Analysis and debugging
npm run size               # Contract size analysis
npm run storage            # Storage layout analysis
npm run slither            # Security analysis with Slither
```

## System Architecture

This is the **OpenEden USDO Protocol** - a yield-bearing USD-pegged token system with institutional compliance features.

### Core Architecture Components

**USDO Token System**:
- `USDO.sol`: Rebasing ERC20 token using shares-based accounting (similar to Lido stETH)
- `cUSDO.sol`: ERC4626 vault wrapper for auto-compounding USDO yields
- Both tokens share security controls: role-based access, pausable operations, ban lists

**USDOExpressV2 System** (`contracts/extensions/USDOExpressV2.sol`):
- Primary business logic contract handling mint/redeem operations
- Instant operations: mint supported assets → USDO, redeem USDO → USDC
- Queue system: handles redemptions when instant liquidity unavailable
- KYC management, fee collection, APY-based bonus multiplier updates
- Supports combined mint-and-wrap operations directly to cUSDO via `instantMintAndWrap()`
- **Asset Registry Integration**: Pluggable asset support without contract upgrades
- **BREAKING CHANGES**: Constructor now requires AssetRegistry parameter, BUIDL references replaced with generic redemption contracts

**Asset Registry System** (`contracts/extensions/AssetRegistry.sol`):
- Pluggable asset configuration without contract upgrades
- **Uses existing `IPriceFeed` interface**: `latestAnswer()` and `decimals()` standard
- Direct integration: TBILL contract itself provides price feed (no adapters needed)
- Hot-swappable: add/remove/update assets instantly via `setAssetConfig()`
- Unified conversion logic for all supported underlying assets

**Redemption Architecture**:
- Pluggable redemption contracts (USYC, BUIDL-based)
- `UsycRedemption.sol`: Redeems USYC tokens to USDC with price feed validation
- Multiple redemption paths: instant (via reserves), queued (batch processing), manual (admin)

### Token Flow Architecture

```
Users → USDOExpressV2 ←→ AssetRegistry (Asset Configs)
            ↓                    ↓
      USDO/cUSDO          IPriceFeed contracts (TBILL, etc.)
            ↓
  Redemption Contracts (USYC/BUIDL)
            ↓
  Underlying Assets (USDC/TBILL/USDT/New Assets)
```

### Key Relationships

1. **Bonus Multiplier System**: USDO uses rebasing via bonus multipliers updated daily by operators
2. **Shares vs. Balance**: USDO tracks user shares; balance = shares × multiplier
3. **Express Integration**: USDOExpressV2 mints/burns USDO based on underlying asset deposits/withdrawals
4. **Compliance Layer**: KYC lists, ban lists, and pausable operations throughout the system

## Smart Contract Patterns

**Access Control**:
- Role-based permissions with OpenZeppelin AccessControl
- Common roles: DEFAULT_ADMIN_ROLE, MINTER_ROLE, BURNER_ROLE, PAUSE_ROLE, WHITELIST_ROLE
- Multi-sig recommended for admin operations

**Upgradeability**:
- UUPS proxy pattern used throughout
- Storage gaps maintained for future upgrades
- Version management in contract inheritance

**Security Patterns**:
- Pausable operations for emergency stops
- Ban list functionality for compliance
- Rate limiting via mint/redeem limits
- Queue system prevents liquidity drain attacks

## Testing and Deployment

**Network Configuration**:
- Multi-chain deployment: Ethereum, Arbitrum, Base, BSC
- Network-specific configs in `config/` directory
- Environment-based deployment scripts

**Testing Approach**:
- TypeScript test suites with Hardhat
- Gas optimization testing
- Mock contracts for external dependencies
- Coverage analysis with Istanbul

**CI/CD Pipeline**:
- Automated security analysis (Slither, Mythril)
- Code quality checks (Prettier, ESLint, Solhint)
- Comprehensive test execution with gas reporting

## Development Workflow Notes

**Queue Management**: The redemption queue system requires careful handling of batch processing operations and user redemption tracking.

**Bonus Multiplier Updates**: Critical that operators call `addBonusMultiplier()` daily within the time buffer to maintain proper yield distribution.

**Price Feed Integration**: USYC redemption relies on external price feeds with staleness checks - monitor feed health in production.

**Liquidity Management**: Express contracts require sufficient backing assets (TBILL, USDC reserves) to support instant operations.

**Upgrade Considerations**: When upgrading, verify storage layout compatibility and test upgrade scripts on testnets first.

**Adding New Assets**: No contract upgrades needed! Use AssetRegistry:
1. Deploy AssetRegistry if not already done
2. Set registry address in USDOExpressV2 via `setAssetRegistry()`  
3. Add new assets via `setAssetConfig()` with appropriate price oracle configuration
4. Examples: USDT (stable, no oracle), FRAX (stable), wstETH (needs price oracle)

## CRITICAL BUG ALERT: Test File Issues

**MAJOR ISSUE**: The current test file `/test/USDOExpress.ts` contains several critical bugs and outdated references:

1. **Constructor Mismatch**: USDOExpressV2 constructor now requires `assetRegistry` parameter (line 169 in USDOExpressV2.sol) but test provides only old parameters
2. **Deprecated Functions**: Test uses `setBuidl()` which has been replaced with `setRedemption()`  
3. **Missing AssetRegistry Setup**: Tests don't initialize or test the AssetRegistry functionality
4. **Parameter Inconsistencies**: Several parameter names and function signatures don't match current implementation

**IMMEDIATE ACTION REQUIRED**: 
- ✅ **FIXED**: Update test constructor to include AssetRegistry deployment and parameter
- ✅ **FIXED**: Replace `setBuidl()` calls with `setRedemption()`
- ✅ **FIXED**: Add comprehensive AssetRegistry test coverage
- ✅ **FIXED**: Update all function calls to match current USDOExpressV2.sol interface

## AssetRegistry Design Clarification

**NOT A BUG**: AssetRegistry.sol:60 intentionally prevents disabling assets via `setAssetConfig()`. This is **good design** that enforces proper API separation:

- **`setAssetConfig()`**: Only for adding new assets (`isSupported: false → true`) and updating existing ones (`isSupported: true → true`)
- **`removeAsset()`**: Dedicated function for explicitly disabling assets (`isSupported: true → false`)

This design prevents accidental asset disabling and makes removal intent explicit. The original error was correct behavior, not a bug.