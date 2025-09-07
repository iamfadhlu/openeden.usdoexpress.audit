// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IMultiEVMPoRAddressList.sol";

/**
 * @title USDOMultiEVMPoRAddressList
 * @dev Contract to manage and expose a list of addresses for Proof of Reserves (PoR).
 */
contract USDOMultiEVMPoRAddressList is Ownable, IMultiEVMPoRAddressList {
    PoRInfo[] private porInfos;

    // Custom errors for gas efficiency
    error IndexOutOfBounds();
    error InvalidIndexRange();

    /**
     * @dev Adds an array of porInfo to the list. Only the owner can call this function.
     * @param _porInfos The PoRInfo infos to add.
     */
    function addPoRInfos(PoRInfo[] memory _porInfos) external onlyOwner {
        for (uint256 i = 0; i < _porInfos.length; i++) {
            porInfos.push(_porInfos[i]);
        }
    }

    /**
     * @dev Removes an PoR info from the list. Only the owner can call this function.
     * @param _index The index of the PoR info to remove.
     */
    function removePoRInfo(uint256 _index) external onlyOwner {
        if (_index >= porInfos.length) revert IndexOutOfBounds();

        // copy the last element to the index being removed
        porInfos[_index] = porInfos[porInfos.length - 1];

        // remove the last element
        porInfos.pop();
    }

    /**
     * @dev Returns the number of PoR info in the list.
     * @return The number of PoR info in the list.
     */
    function getPoRAddressListLength() external view returns (uint256) {
        return porInfos.length;
    }

    /**
     * @dev Returns a batch of PoRInfo entries from the list.
     * @param _startIndex The starting index (inclusive).
     * @param _endIndex The ending index (inclusive).
     * @return list The list of PoRInfo entries.
     */
    function getPoRAddressList(uint256 _startIndex, uint256 _endIndex) external view returns (PoRInfo[] memory list) {
        if (_startIndex > _endIndex || _startIndex >= porInfos.length) revert InvalidIndexRange();
        if (_endIndex >= porInfos.length) {
            _endIndex = porInfos.length - 1;
        }

        uint256 rangeLength = _endIndex - _startIndex + 1;
        list = new PoRInfo[](rangeLength);

        for (uint256 i = 0; i < rangeLength; i++) {
            list[i] = porInfos[_startIndex + i];
        }
    }
}
