// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface IUSDO {
    function bonusMultiplier() external view returns (uint256);

    function addBonusMultiplier(uint256 _bonusMultiplierIncrement) external;

    function approve(address spender, uint256 amount) external returns (bool);

    function mint(address to, uint256 amount) external;

    function burn(address from, uint256 amount) external;

    function pause() external;

    function unpause() external;

    function totalSupply() external view returns (uint256);
}
