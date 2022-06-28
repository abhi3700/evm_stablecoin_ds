// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

// Common interface for the Trove Manager.
interface IBorrowerOperations {
    // --- Events ---

    // event TroveManagerAddressChanged(address _newTroveManagerAddress);
    // event ActivePoolAddressChanged(address _activePoolAddress);
    // event DefaultPoolAddressChanged(address _defaultPoolAddress);
    // event StabilityPoolAddressChanged(address _stabilityPoolAddress);
    // event GasPoolAddressChanged(address _gasPoolAddress);
    // event CollSurplusPoolAddressChanged(address _collSurplusPoolAddress);
    // event PriceFeedAddressChanged(address _newPriceFeedAddress);
    // event SortedTrovesAddressChanged(address _sortedTrovesAddress);
    // event YUSDTokenAddressChanged(address _yusdTokenAddress);
    // event sMOJOAddressChanged(address _sMOJOAddress);

    // event TroveCreated(address indexed _borrower, uint256 arrayIndex);
    // event TroveUpdated(
    //     address indexed _borrower,
    //     uint256 _debt,
    //     uint256 _coll,
    //     uint8 operation
    // );
    // event USMBorrowingFeePaid(address indexed _borrower, uint256 _USMFee);

    // --- Functions ---

    // function setAddresses(
    //     address _troveManagerAddress,
    //     address _activePoolAddress,
    //     address _defaultPoolAddress,
    //     address _stabilityPoolAddress,
    //     address _gasPoolAddress,
    //     address _collSurplusPoolAddress,
    //     address _sortedTrovesAddress,
    //     address _yusdTokenAddress,
    //     address _sMOJOAddress,
    //     address _whiteListAddress
    // ) external;

    function openTrove(
        uint256 _maxFeePercentage,
        uint256 _USMAmount,
        address _upperHint,
        address _lowerHint,
        address[] calldata _colls,
        uint256[] calldata _amounts
    ) external;

    function openTroveLeverUp(
        uint256 _maxFeePercentage,
        uint256 _USMAmount,
        address _upperHint,
        address _lowerHint,
        address[] memory _colls,
        uint256[] memory _amounts,
        uint256[] memory _leverages,
        uint256[] calldata _maxSlippages
    ) external;

    function closeTroveUnlever(
        address[] calldata _collsOut,
        uint256[] calldata _amountsOut,
        uint256[] calldata _maxSlippages
    ) external;

    function closeTrove() external;

    function adjustTrove(
        address[] memory _collsIn,
        uint256[] memory _amountsIn,
        address[] memory _collsOut,
        uint256[] memory _amountsOut,
        uint256 _USMChange,
        bool _isDebtIncrease,
        address _upperHint,
        address _lowerHint,
        uint256 _maxFeePercentage
    ) external;

    function addColl(
        address[] calldata _collsIn,
        uint256[] calldata _amountsIn,
        address _upperHint,
        address _lowerHint,
        uint256 _maxFeePercentage
    ) external;

    function addCollLeverUp(
        address[] memory _collsIn,
        uint256[] memory _amountsIn,
        uint256[] memory _leverages,
        uint256[] memory _maxSlippages,
        uint256 _USMAmount,
        address _upperHint,
        address _lowerHint,
        uint256 _maxFeePercentage
    ) external;

    function withdrawColl(
        address[] calldata _collsOut,
        uint256[] calldata _amountsOut,
        address _upperHint,
        address _lowerHint
    ) external;

    function withdrawCollUnleverUp(
        address[] calldata _collsOut,
        uint256[] calldata _amountsOut,
        uint256[] calldata _maxSlippages,
        uint256 _USMAmount,
        address _upperHint,
        address _lowerHint
    ) external;

    function withdrawUSM(
        uint256 _maxFeePercentage,
        uint256 _USMAmount,
        address _upperHint,
        address _lowerHint
    ) external;

    function repayUSM(
        uint256 _USMAmount,
        address _upperHint,
        address _lowerHint
    ) external;

    function claimCollateral() external;

    function getCompositeDebt(uint256 _debt) external pure returns (uint256);
}
