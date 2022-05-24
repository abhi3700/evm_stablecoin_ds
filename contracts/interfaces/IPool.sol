// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "./ICollateralReceiver.sol";

// Common interface for the Pools.
interface IPool is ICollateralReceiver {
    // --- Events ---

    // event ETHBalanceUpdated(uint256 _newBalance);
    // event YUSDBalanceUpdated(uint256 _newBalance);
    // event ActivePoolAddressChanged(address _newActivePoolAddress);
    event DefaultPoolAddressChanged(address _newDefaultPoolAddress);
    event StabilityPoolAddressChanged(address _newStabilityPoolAddress);
    event WhitelistAddressChanged(address _newWhitelistAddress);
    // event EtherSent(address _to, uint256 _amount);
    event CollateralSent(address _collateral, address _to, uint256 _amount);

    // --- Functions ---

    function getVC() external view returns (uint256);

    function getCollateral(address collateralAddress)
        external
        view
        returns (uint256);

    function getAllCollateral()
        external
        view
        returns (address[] memory, uint256[] memory);

    function getUSMDebt() external view returns (uint256);

    function increaseUSMDebt(uint256 _amount) external;

    function decreaseUSMDebt(uint256 _amount) external;
}
