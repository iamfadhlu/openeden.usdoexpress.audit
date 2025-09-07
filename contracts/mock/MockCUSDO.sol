// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../interfaces/ICUSDO.sol";

contract MockCUSDO is ERC20, ICUSDO {
    IERC20 public underlying;

    constructor(address _underlying) ERC20("Mock cUSDO", "mcUSDO") {
        underlying = IERC20(_underlying);
    }

    function deposit(uint256 assets, address receiver) external override returns (uint256) {
        // Simple 1:1 conversion for testing
        _mint(receiver, assets);
        return assets;
    }

    function withdraw(uint256 assets, address receiver, address owner) external override returns (uint256) {
        // Simple 1:1 conversion for testing
        receiver;
        _burn(owner, assets);
        return assets;
    }

    function maxDeposit(address receiver) external pure override returns (uint256) {
        receiver;
        return type(uint256).max;
    }

    function maxWithdraw(address owner) external view override returns (uint256) {
        return balanceOf(owner);
    }

    function previewDeposit(uint256 assets) external pure override returns (uint256) {
        // Simple 1:1 conversion for testing
        return assets;
    }
}
