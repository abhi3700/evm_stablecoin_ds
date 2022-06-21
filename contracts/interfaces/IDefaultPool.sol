// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

interface IDefaultPool {
    // --- Events ---
    // event DefaultPoolETHBalanceUpdated(uint _ETH);
    event ActivePoolAddressChanged(address _newActivePoolAddress);
    event CollateralSent(address _collateral, address _to, uint256 _amount);
    event TroveManagerAddressChanged(address _newTroveManagerAddress);
    event DefaultPoolUSMDebtUpdated(uint256 _USMDebt);
    event DefaultPoolBalanceUpdated(address _collateral, uint256 _amount);
    event DefaultPoolBalancesUpdated(
        address[] _collaterals,
        uint256[] _amounts
    );

    // --- Functions ---

    function sendCollsToActivePool(
        address[] memory _collaterals,
        uint256[] memory _amounts,
        address _borrower
    ) external;

    function addCollateralTypeD(address _collateral) external;

    function getCollateralVCD(address collateralAddress)
        external
        view
        returns (uint256);

    function receiveCollateralD(
        address[] memory _tokens,
        uint256[] memory _amounts
    ) external;
}
