// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface ICUSDO {
    function deposit(uint256 assets, address receiver) external returns (uint256);

    function withdraw(uint256 assets, address receiver, address owner) external returns (uint256);

    function maxDeposit(address receiver) external view returns (uint256);

    function maxWithdraw(address owner) external view returns (uint256);

    function previewDeposit(uint256 assets) external view returns (uint256);
}
