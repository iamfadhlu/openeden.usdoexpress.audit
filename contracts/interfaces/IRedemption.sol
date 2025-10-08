// SPDX-License-Identifier: MIT
pragma solidity =0.8.18;

interface IRedemption {
    function checkLiquidity() external view returns (uint256, uint256, uint256, uint256, uint256, uint256);

    function checkPaused() external view returns (bool);

    function redeem(uint256 amount) external returns (uint256 payout, uint256 fee, int256 price);
}
