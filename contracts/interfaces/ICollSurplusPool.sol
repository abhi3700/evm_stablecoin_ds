// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

// import "../MojoCustomBase.sol";
import "./ICollateralReceiver.sol";

interface ICollSurplusPool is ICollateralReceiver {
    // --- Events ---

    event BorrowerOperationsAddressChanged(
        address _newBorrowerOperationsAddress
    );
    event TroveManagerAddressChanged(address _newTroveManagerAddress);
    event ActivePoolAddressChanged(address _newActivePoolAddress);

    event CollBalanceUpdated(address indexed _account);
    event CollateralSent(address _to);

    // --- Contract setters ---

    function setAddresses(
        address _borrowerOperationsAddress,
        address _troveManagerAddress,
        address _troveManagerRedemptionsAddress,
        address _activePoolAddress,
        address _whitelistAddress
    ) external;

    function getCollVC() external view returns (uint256);

    function getAmountClaimable(address _account, address _collateral)
        external
        view
        returns (uint256);

    function getCollateral(address _collateral) external view returns (uint256);

    function getAllCollateral()
        external
        view
        returns (address[] memory, uint256[] memory);

    function accountSurplus(
        address _account,
        address[] memory _tokens,
        uint256[] memory _amounts
    ) external;

    function claimColl(address _account) external;

    function addCollateralType(address _collateral) external;
}
