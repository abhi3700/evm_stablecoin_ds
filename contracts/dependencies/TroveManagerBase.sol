// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "../interfaces/ITroveManager.sol";
// import "../interfaces/IStabilityPool.sol";
import "../interfaces/ICollSurplusPool.sol";
import "../interfaces/IUSMToken.sol";
import "../interfaces/ISortedTroves.sol";
import "../interfaces/IMOJOToken.sol";
import "../interfaces/ISMOJO.sol";
import "../interfaces/IActivePool.sol";
import "../interfaces/ITroveManagerLiquidations.sol";
import "../interfaces/ITroveManagerRedemptions.sol";
import "./LiquityBase.sol";
// import "./Ownable.sol";
import "./CheckContract.sol";
import "../libs/LibMojoDiamond.sol";

/**
 * Contains shared functionality of TroveManagerLiquidations, TroveManagerRedemptions, and TroveManager.
 * Keeps addresses to cache, events, structs, status, etc. Also keeps Trove struct.
 */

abstract contract TroveManagerBase is LiquityBase, CheckContract {
    // --- Connected contract declarations ---

    // A doubly linked list of Troves, sorted by their sorted by their individual collateral ratios

    // struct ContractsCache {
    //     IActivePool activePool;
    //     IDefaultPool defaultPool;
    //     IYUSDToken yusdToken;
    //     ISYETI sYETI;
    //     ISortedTroves sortedTroves;
    //     ICollSurplusPool collSurplusPool;
    //     address gasPoolAddress;
    // }

    // struct SingleRedemptionValues {
    //     uint256 YUSDLot;
    //     newColls CollLot;
    //     bool cancelledPartial;
    // }

    // enum Status {
    //     nonExistent,
    //     active,
    //     closedByOwner,
    //     closedByLiquidation,
    //     closedByRedemption
    // }

    // enum TroveManagerOperation {
    //     applyPendingRewards,
    //     liquidateInNormalMode,
    //     liquidateInRecoveryMode,
    //     redeemCollateral
    // }

    // // Store the necessary data for a trove
    // struct Trove {
    //     newColls colls;
    //     uint256 debt;
    //     mapping(address => uint256) stakes;
    //     Status status;
    //     uint128 arrayIndex;
    // }

    event BorrowerOperationsAddressChanged(
        address _newBorrowerOperationsAddress
    );
    event YUSDTokenAddressChanged(address _newYUSDTokenAddress);
    event ActivePoolAddressChanged(address _activePoolAddress);
    event DefaultPoolAddressChanged(address _defaultPoolAddress);
    event StabilityPoolAddressChanged(address _stabilityPoolAddress);
    event GasPoolAddressChanged(address _gasPoolAddress);
    event CollSurplusPoolAddressChanged(address _collSurplusPoolAddress);
    event SortedTrovesAddressChanged(address _sortedTrovesAddress);
    event YETITokenAddressChanged(address _yetiTokenAddress);
    event SYETIAddressChanged(address _sYETIAddress);

    event TroveUpdated(
        address indexed _borrower,
        uint256 _debt,
        address[] _tokens,
        uint256[] _amounts,
        LibMojoDiamond.TroveManagerOperation operation
    );
}
