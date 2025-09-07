// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;
import "@openzeppelin/contracts/access/AccessControl.sol";

/// @title USDOPoRAssetsTracking
/// @notice Contract for tracking assets in subscription and redemption flows
/// @dev All amounts passed to this contract are assumed to be in 6 decimals
/// @dev For example: 1000 means 0.001 (1000 * 10^-6)
contract USDOPoRAssetsTracking is AccessControl {
    // Custom errors
    error ZeroAmount();
    error ZeroAddress();
    error Unauthorized();
    error AssetNotSupported(address asset);
    error DuplicateAsset(address asset);

    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    // for sub request and redeem req
    event Increase(address indexed assetAddr, uint256 amount);

    // for sub request and redeem request
    event Decrease(address indexed assetAddr, uint256 amount);
    event SetPending(uint256 amount);

    event AssetAdded(address indexed asset);
    event AssetRemoved(address indexed asset);

    // decimals of the assets
    uint256 public constant decimals = 6;

    uint256 private _pendingAmount;

    // Supported assets
    address[] private _supportedAssets;
    mapping(address => bool) private _isAssetSupported;

    constructor(address _admin, address _operator) {
        if (_admin == address(0)) revert ZeroAddress();
        if (_operator == address(0)) revert ZeroAddress();

        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(OPERATOR_ROLE, _operator);
    }

    ////////////////////////////////////////////////////////////////////////
    //    Subscription functions
    ////////////////////////////////////////////////////////////////////////

    /// @notice Increase subscription amount for a token
    /// @param _assetAddr Token address
    /// @param _amount Amount to increase
    function increase(address _assetAddr, uint256 _amount) external onlyRole(OPERATOR_ROLE) {
        if (_amount == 0) revert ZeroAmount();
        if (!_isAssetSupported[_assetAddr]) revert AssetNotSupported(_assetAddr);
        _pendingAmount += _amount;
        emit Increase(_assetAddr, _amount);
    }

    /// @notice Decrease subscription amount for a token
    /// @param _assetAddr Token address
    /// @param _amount Amount to decrease
    function decrease(address _assetAddr, uint256 _amount) external onlyRole(OPERATOR_ROLE) {
        if (_amount == 0) revert ZeroAmount();
        if (!_isAssetSupported[_assetAddr]) revert AssetNotSupported(_assetAddr);
        if (_pendingAmount < _amount) revert ZeroAmount();

        _pendingAmount -= _amount;
        emit Decrease(_assetAddr, _amount);
    }

    /// @notice Set subscription pending amount manually
    /// @param _amount New pending amount
    function setPending(uint256 _amount) external onlyRole(OPERATOR_ROLE) {
        _pendingAmount = _amount;
        emit SetPending(_amount);
    }

    ////////////////////////////////////////////////////////////////////////
    //  Support asset functions
    ////////////////////////////////////////////////////////////////////////

    /// @notice Add supported assets
    /// @param _assets Array of asset addresses to add
    function addSupportAsset(address[] calldata _assets) external onlyRole(OPERATOR_ROLE) {
        uint256 length = _assets.length;
        for (uint256 i; i < length; ) {
            address asset = _assets[i];
            if (asset == address(0)) revert ZeroAddress();
            if (_isAssetSupported[asset]) revert DuplicateAsset(asset);

            _isAssetSupported[asset] = true;
            _supportedAssets.push(asset);
            emit AssetAdded(asset);

            unchecked {
                ++i;
            }
        }
    }

    /// @notice Remove supported assets
    /// @param _assets Array of asset addresses to remove
    function removeSupportAssets(address[] calldata _assets) external onlyRole(OPERATOR_ROLE) {
        if (_assets.length == 0) revert ZeroAmount();
        uint256 length = _assets.length;
        for (uint256 i; i < length; ) {
            address asset = _assets[i];
            if (!_isAssetSupported[asset]) revert AssetNotSupported(asset);

            _isAssetSupported[asset] = false;
            // Optimized removal from array
            uint256 assetsLength = _supportedAssets.length;
            if (assetsLength > 0) {
                for (uint256 j; j < assetsLength; ) {
                    if (_supportedAssets[j] == asset) {
                        if (j != assetsLength - 1) {
                            _supportedAssets[j] = _supportedAssets[assetsLength - 1];
                        }
                        _supportedAssets.pop();
                        break;
                    }
                    unchecked {
                        ++j;
                    }
                }
            }
            emit AssetRemoved(asset);

            unchecked {
                ++i;
            }
        }
    }

    ////////////////////////////////////////////////////////////////////////
    //  Getter functions
    ////////////////////////////////////////////////////////////////////////

    /// @notice Get list of supported assets
    function getSupportAssets() external view returns (address[] memory) {
        return _supportedAssets;
    }

    /// @notice Check if an asset is supported
    /// @param _asset Asset address to check
    function isAssetSupported(address _asset) external view returns (bool) {
        return _isAssetSupported[_asset];
    }

    /// @notice Get current pending amount
    /// @return totalPending Total pending amount
    function getPending() external view returns (uint256) {
        return _pendingAmount;
    }
}
