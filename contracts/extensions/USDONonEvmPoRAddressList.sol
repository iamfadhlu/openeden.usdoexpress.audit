// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/INonEvmPoRAddressList.sol";

contract USDONonEvmPoRAddressList is INonEvmPoRAddressList, Ownable {
    string[] private addresses;
    string public name;

    // Custom errors for gas efficiency
    error IndexOutOfBounds();

    constructor(string memory _name, string[] memory _addresses) {
        name = _name;
        addresses = _addresses;
    }

    /**
     * @dev Adds an array of addresses to the list. Only the owner can call this function.
     * @param _addresses The addresses to add.
     */
    function addPoRAddresses(string[] memory _addresses) external onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            addresses.push(_addresses[i]);
        }
    }

    /**
     * @dev Removes an address from the list. Only the owner can call this function.
     * @param _index The index of the address to remove.
     */
    function removePoRAddress(uint256 _index) external onlyOwner {
        if (_index >= addresses.length) revert IndexOutOfBounds();

        // copy the last element to the index being removed
        addresses[_index] = addresses[addresses.length - 1];

        // remove the last element
        addresses.pop();
    }

    function getPoRAddressListLength() external view override returns (uint256) {
        return addresses.length;
    }

    function getPoRAddressList(uint256 startIndex, uint256 endIndex) external view override returns (string[] memory) {
        if (startIndex > endIndex) {
            return new string[](0);
        }
        endIndex = endIndex > addresses.length - 1 ? addresses.length - 1 : endIndex;
        string[] memory stringAddresses = new string[](endIndex - startIndex + 1);
        uint256 currIdx = startIndex;
        uint256 strAddrIdx = 0;
        while (currIdx <= endIndex) {
            stringAddresses[strAddrIdx] = addresses[currIdx];
            strAddrIdx++;
            currIdx++;
        }
        return stringAddresses;
    }
}
