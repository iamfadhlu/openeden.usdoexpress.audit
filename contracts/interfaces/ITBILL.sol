// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface ITBILL {
    function tbillUsdcRate() external view returns (uint256 rate);

    function redeemIns(uint256 _shares, address _receiver) external returns (uint256);
}
