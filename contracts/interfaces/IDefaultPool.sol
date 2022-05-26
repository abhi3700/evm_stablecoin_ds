// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "./IPool.sol";

interface IDefaultPool is IPool {
    // --- Events ---
    // event TroveManagerAddressChanged(address _newTroveManagerAddress);
    // event DefaultPoolYUSDDebtUpdated(uint _YUSDDebt);
    // event DefaultPoolETHBalanceUpdated(uint _ETH);

    // --- Functions ---

    function sendCollsToActivePool(
        address[] memory _collaterals,
        uint256[] memory _amounts,
        address _borrower
    ) external;

    function addCollateralType(address _collateral) external;

    function getCollateralVC(address collateralAddress)
        external
        view
        returns (uint256);
}
