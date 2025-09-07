// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "../interfaces/IPriceFeed.sol";

contract MockTBILL is ERC20, IPriceFeed {
    using MathUpgradeable for uint256;

    uint256 public constant _tbillDecimalScaleFactor = 10 ** 6;
    uint256 public _tbillUsdcRate;
    address public immutable _usdc;

    constructor(address usdc) ERC20("Mock TBILL", "TBILL") {
        _usdc = usdc;
        _mint(msg.sender, 100000000000000000000000000000 * 10 ** decimals());
    }

    function decimals() public view virtual override(ERC20, IPriceFeed) returns (uint8) {
        return 6;
    }

    // _rate: 1.01 * 10 ** 6;
    function setTbillUsdcRate(uint256 _rate) external {
        _tbillUsdcRate = _rate;
    }

    function tbillUsdcRate() public view returns (uint256 rate) {
        return _tbillUsdcRate;
    }

    // IPriceFeed implementation
    function latestAnswer() external view override returns (uint256) {
        return _tbillUsdcRate;
    }

    function latestRoundData()
        external
        view
        override
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        return (1, int256(_tbillUsdcRate), block.timestamp, block.timestamp, 1);
    }

    function redeemIns(uint256 _shares, address _receiver) external returns (uint256) {
        uint256 _assets = _convertToAssets(_shares);
        _burn(msg.sender, _shares);

        SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(_usdc), _receiver, _assets);
        return _assets;
    }

    /**
     * @dev Converts the number of shares to asset amount.
     * @param _shares Number of shares to convert.
     * @return assets Equivalent asset amount.
     */
    function _convertToAssets(uint256 _shares) internal view returns (uint256 assets) {
        assets = _shares.mulDiv(tbillUsdcRate(), _tbillDecimalScaleFactor);
    }

    /**
     * @dev Converts asset amount to the equivalent number of shares.
     * @param _assets Asset amount to convert.
     * @return shares Equivalent number of shares.
     */
    function _convertToShares(uint256 _assets) internal view returns (uint256 shares) {
        shares = _assets.mulDiv(_tbillDecimalScaleFactor, tbillUsdcRate());
    }
}
