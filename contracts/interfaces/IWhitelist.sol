// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

interface IWhitelist {
    function getValidCollateral() external view returns (address[] memory);

    function setAddresses(
        address _activePoolAddress,
        address _defaultPoolAddress,
        address _stabilityPoolAddress,
        address _collSurplusPoolAddress,
        address _borrowerOperationsAddress
    ) external;

    function isValidRouter(address _router) external view returns (bool);

    function getOracle(address _collateral) external view returns (address);

    function getRatio(address _collateral) external view returns (uint256);

    function getIsActive(address _collateral) external view returns (bool);

    function getPriceCurve(address _collateral) external view returns (address);

    function getDecimals(address _collateral) external view returns (uint256);

    function getFee(
        address _collateral,
        uint256 _collateralVCInput,
        uint256 _collateralVCBalancePost,
        uint256 _totalVCBalancePre,
        uint256 _totalVCBalancePost
    ) external view returns (uint256 fee);

    function getFeeAndUpdate(
        address _collateral,
        uint256 _collateralVCInput,
        uint256 _collateralVCBalancePost,
        uint256 _totalVCBalancePre,
        uint256 _totalVCBalancePost
    ) external returns (uint256 fee);

    function getIndex(address _collateral) external view returns (uint256);

    function isWrapped(address _collateral) external view returns (bool);

    function setDefaultRouter(address _collateral, address _router) external;

    function getValueVC(address _collateral, uint256 _amount)
        external
        view
        returns (uint256);

    function getValueUSD(address _collateral, uint256 _amount)
        external
        view
        returns (uint256);

    function getDefaultRouterAddress(address _collateral)
        external
        view
        returns (address);
}
