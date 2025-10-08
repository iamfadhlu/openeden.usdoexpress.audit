// SPDX-License-Identifier: MIT
pragma solidity =0.8.18;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "../../interfaces/IRedemption.sol";
import "../../interfaces/IPriceFeed.sol";

error UnauthorizedCaller();
error ZeroAddress();
error StalePrice(uint256 updatedAt, uint256 maxAge);
error InvalidPrice(int256 price);
error InsufficientUSDCReceived(uint256 received, uint256 required);
error ExcessiveSellFee(uint256 feeRate);

interface IUsycHelper {
    /**
     * @notice Sell USYC tokens and receive USDC
     * @param amount Amount of USYC tokens to sell
     * @param recipient Address to receive USDC
     * @return Amount of USDC received

     */
    function sellFor(uint256 amount, address recipient) external returns (uint256);

    /**
     * @notice Preview a sale of Yield Token
     * @dev Produces the anticipated payout and fees using a price.
     *      Total amount of yield token is rounded down to 2 decimals (cents)
     *      sending more precision will not be used in payout calculation
     * @param amount is the amount of Yield Token to sell
     * @return payout amount of stablecoin received
     * @return fee taken
     * @return price used in conversion
     */
    function sellPreview(uint256 amount) external view returns (uint256 payout, uint256 fee, int256 price);

    /**
     * @notice Check if selling is currently paused
     * @return true if selling is paused, false otherwise
     */
    function sellPaused() external view returns (bool);

    function sellFee() external view returns (uint256);

    function oracle() external view returns (address);
}

/**
 * @title UsycRedemption
 * @dev Implements instant redemption of USYC tokens to USDC using USYC's sell function
 * @dev Pausable by the owner
 * @dev Asset token (USDC) is ERC20-compatible
 * @dev USYC token implements IUsyc interface with sell function
 * @dev Upgradeable using UUPS pattern
 */
contract UsycRedemption is IRedemption, OwnableUpgradeable, UUPSUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using MathUpgradeable for uint256;

    uint256 public constant MAX_PRICE_AGE = 3 days; // 3-day buffer
    uint256 public minPrice;
    uint256 public scaleFactor;
    uint8 public usycDecimals;
    uint8 public usdcDecimals;

    address public usyc;
    address public usdc;
    address public helper;
    address public caller;
    address public usycTreasury;
    uint256 public RESERVE1;
    address public RESERVE2;
    uint256 public maxSellFeeRate;

    uint256 public constant FEE_MULTIPLIER = 10 ** 18;
    uint256 public constant HUNDRED_PCT = 100 * FEE_MULTIPLIER;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initialize the contract
     * @param _usyc USYC token address
     * @param _usdc USDC token address
     * @param _helper USYC helper contract address
     * @param _caller Authorized caller address
     * @param _usycTreasury USYC treasury address
     */
    function initialize(
        address _usyc,
        address _usdc,
        address _helper,
        address _caller,
        address _usycTreasury
    ) public initializer {
        if (_usyc == address(0)) revert ZeroAddress();
        if (_usdc == address(0)) revert ZeroAddress();
        if (_helper == address(0)) revert ZeroAddress();
        if (_caller == address(0)) revert ZeroAddress();
        if (_usycTreasury == address(0)) revert ZeroAddress();

        __Ownable_init();
        __UUPSUpgradeable_init();

        usyc = _usyc;
        usdc = _usdc;
        helper = _helper;
        caller = _caller;
        usycTreasury = _usycTreasury;

        // Get decimals from both tokens
        usycDecimals = IERC20MetadataUpgradeable(_usyc).decimals();
        usdcDecimals = IERC20MetadataUpgradeable(_usdc).decimals();

        scaleFactor = 10 ** IPriceFeed(IUsycHelper(helper).oracle()).decimals();
        minPrice = 1 * scaleFactor;
    }

    /**
     * @notice Set the maximum sell fee rate (only owner)
     * @param _maxRate Maximum sell fee rate
     */
    function setMaxSellFeeRate(uint256 _maxRate) external onlyOwner {
        maxSellFeeRate = _maxRate;
    }

    /**
     * @notice Redeem USYC tokens for USDC using USYC's sell function
     * @param _amount Amount of USDC desired to receive
     * @return payout usdc amount
     * @return fee charged by usdc amount
     * @return price used in conversion
     */
    function redeem(uint256 _amount) external override returns (uint256 payout, uint256 fee, int256 price) {
        if (msg.sender != caller) revert UnauthorizedCaller();

        uint256 sellFeeRate = IUsycHelper(helper).sellFee();
        if (sellFeeRate > maxSellFeeRate) revert ExcessiveSellFee(sellFeeRate);

        uint256 usycAmount = convertUsdcToToken(_amount);

        SafeERC20Upgradeable.safeTransferFrom(IERC20Upgradeable(usyc), usycTreasury, address(this), usycAmount);
        SafeERC20Upgradeable.safeIncreaseAllowance(IERC20Upgradeable(usyc), helper, usycAmount);

        IUsycHelper(helper).sellFor(usycAmount, address(caller));

        (payout, fee, price) = IUsycHelper(helper).sellPreview(usycAmount);
    }

    /**
     * @notice Check the available liquidity for instant redeem.
     * @return liquidity The available liquidity from the redemption contract.
     * @return tAllowance The redemption token allowance for the vault.
     * @return tBalance The redemption token balance in the Treasury.
     * @return tAllowanceInUsdc The redemption token allowance in USDC.
     * @return tBalanceInUsdc The redemption token balance in USDC.
     * @return minimum The minimum of the available liquidity, the redemption token allowance, and the redemption token balance in USDC.
     */
    function checkLiquidity()
        public
        view
        override
        returns (
            uint256 liquidity,
            uint256 tAllowance,
            uint256 tBalance,
            uint256 tAllowanceInUsdc,
            uint256 tBalanceInUsdc,
            uint256 minimum
        )
    {
        liquidity = IERC20Upgradeable(usdc).balanceOf(helper);

        tAllowance = IERC20Upgradeable(usyc).allowance(usycTreasury, address(this));
        tAllowanceInUsdc = convertTokenToUsdc(tAllowance);

        tBalance = IERC20Upgradeable(usyc).balanceOf(usycTreasury);
        tBalanceInUsdc = convertTokenToUsdc(tBalance);

        minimum = liquidity.min(tAllowanceInUsdc.min(tBalanceInUsdc));
    }

    /**
     * @notice Check if USYC selling is currently available
     * @return false if USYC can be sold, true otherwise
     */
    function checkPaused() external view returns (bool) {
        return IUsycHelper(helper).sellPaused();
    }

    function getPrice(address _oracle) public view returns (uint256) {
        (uint80 roundId, int256 price, , uint256 updatedAt, uint80 answeredInRound) = IPriceFeed(_oracle)
            .latestRoundData();

        // Check if the price data is not older than 3 days
        if (block.timestamp - updatedAt > MAX_PRICE_AGE) {
            revert StalePrice(updatedAt, MAX_PRICE_AGE);
        }

        // Check for incomplete round data
        if (answeredInRound < roundId) {
            revert StalePrice(updatedAt, MAX_PRICE_AGE);
        }

        if (uint256(price) < minPrice) revert InvalidPrice(price);
        return uint256(price);
    }

    function convertUsdcToToken(uint256 _amount) public view returns (uint256) {
        uint256 price = getPrice(IUsycHelper(helper).oracle());
        // Convert USDC amount to USYC token amount accounting for decimal differences
        // Formula: (usdcAmount * 10^usycDecimals * scaleFactor) / (price * 10^usdcDecimals)
        return
            _amount.mulDiv(10 ** usycDecimals * scaleFactor, price * 10 ** usdcDecimals, MathUpgradeable.Rounding.Up);
    }

    function convertTokenToUsdc(uint256 _amount) public view returns (uint256) {
        uint256 price = getPrice(IUsycHelper(helper).oracle());
        // Convert USYC token amount to USDC amount accounting for decimal differences
        // Formula: (usycAmount * price * 10^usdcDecimals) / (scaleFactor * 10^usycDecimals)
        return
            _amount.mulDiv(price * 10 ** usdcDecimals, scaleFactor * 10 ** usycDecimals, MathUpgradeable.Rounding.Down);
    }

    /**
     * @notice Set the caller address (only owner)
     * @param _caller Address of the caller
     */
    function setCaller(address _caller) external onlyOwner {
        if (_caller == address(0)) revert ZeroAddress();
        caller = _caller;
    }

    /**
     * @notice Set the USYC treasury address (only owner)
     * @param _usycTreasury Address of the USYC treasury
     */
    function setUsycTreasury(address _usycTreasury) external onlyOwner {
        if (_usycTreasury == address(0)) revert ZeroAddress();
        usycTreasury = _usycTreasury;
    }

    /**
     * @notice Emergency withdraw function for owner to withdraw stuck tokens
     * @param token Token address to withdraw
     * @param amount Amount to withdraw
     */
    function emergencyWithdraw(address token, uint256 amount) external onlyOwner {
        if (token == address(0)) revert ZeroAddress();
        SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(token), owner(), amount);
    }

    /**
     * @notice Required by the OZ UUPS module
     * @dev Only owner can upgrade the contract
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
