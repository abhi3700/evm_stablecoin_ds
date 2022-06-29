// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "./IPool.sol";

interface IActivePool is IPool {
    // --- Events ---
    // event BorrowerOperationsAddressChanged(
    //     address _newBorrowerOperationsAddress
    // );
    // event TroveManagerAddressChanged(address _newTroveManagerAddress);
    // event ActivePoolYUSDDebtUpdated(uint256 _YUSDDebt);
    // event ActivePoolCollateralBalanceUpdated(
    //     address _collateral,
    //     uint256 _amount
    // );

    // --- Functions ---

    function sendCollaterals(
        address _to,
        address[] memory _tokens,
        uint256[] memory _amounts
    ) external returns (bool);

    function sendCollateralsUnwrap(
        address _from,
        address _to,
        address[] memory _tokens,
        uint256[] memory _amounts
    ) external returns (bool);

    function sendSingleCollateral(
        address _to,
        address _token,
        uint256 _amount
    ) external returns (bool);

    function sendSingleCollateralUnwrap(
        address _from,
        address _to,
        address _token,
        uint256 _amount
    ) external returns (bool);

    function getCollateralVC(address collateralAddress)
        external
        view
        returns (uint256);

    function addCollateralType(address _collateral) external;
}
