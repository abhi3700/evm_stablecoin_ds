// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import {IDiamondCut} from "../interfaces/IDiamondCut.sol";
import "../interfaces/IWhitelist.sol";
import "../interfaces/IActivePool.sol";
import "../interfaces/IDefaultPool.sol";
import "../interfaces/ICollSurplusPool.sol";
import "../interfaces/ITroveManager.sol";
import "../interfaces/ISMOJO.sol";
import "../interfaces/IUSMToken.sol";
import "../interfaces/ISortedTroves.sol";
import "../interfaces/IBorrowerOperations.sol";

library LibMojoDiamond {
    /**
     * ****************************************
     *
     * Errors
     * ****************************************
     LIBE0: the caller is not a owner
     LIBE1: Mojo SC was not paused
     LIBE2: Mojo SC was paused
     LIBE3: the diamond cut action is not correct
     LIBE4: the function selectors are empty
     LIBE5: the facet address can not be zero_address.
     LIBE6: the function already exists
     LIBE7: the facet has no code
     LIBE8: the function does not exist
     LIBE9: the function is immutable.
     LIBE10: CALL_DATA is not empty
     LIBE11: CALL_DATA is empty
     LIBE12: the init address has no code
     LIBE13: while executing init code, the transaction was reverted
     */

    bytes32 internal constant DIAMOND_STORAGE_POSITION =
        keccak256("mojo.xyz.diamond.storage");

    struct FacetAddressAndPosition {
        address facetAddress;
        uint96 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
    }

    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint256 facetAddressPosition; // position of facetAddress in facetAddresses array
    }

    struct AllAddresses2 {
        address borrowerOperationsAddress;
        address troveManagerAddress;
        address troveManagerLiquidationsAddress;
        address troveManagerRedemptionsAddress;
    }

    struct AllAddresses {
        address mojoCustomBaseAddress;
        address activePoolAddress;
        // address stabilityPoolAddress;
        address defaultPoolAddress;
        address whitelistAddress;
        address gasPoolAddress;
        address collSurplusPoolAddress;
        address mojoFinanceTreasury;
        address sortedTroveAddress;
        address usmTokenAddress;
        address mojoTokenAddress;
        address sMOJOAddress;
    }

    // ========"ActivePool.sol" | "DefaultPool.sol"========
    struct newColls {
        // tokens and amounts should be the same length
        address[] tokens;
        uint256[] amounts;
    }

    // ========"Whitelist.sol"========
    struct CollateralParams {
        // Safety ratio
        uint256 ratio; // 10**18 * the ratio. i.e. ratio = .95 * 10**18 for 95%. More risky collateral has a lower ratio
        address oracle;
        uint256 decimals;
        address priceCurve;
        uint256 index;
        bool active;
        bool isWrapped;
        address defaultRouter;
    }

    // ========"BorrowerOperations.sol"========
    struct CollateralData {
        address collateral;
        uint256 amount;
    }

    struct DepositFeeCalc {
        uint256 collateralUSMFee;
        uint256 systemCollateralVC;
        uint256 collateralInputVC;
        uint256 systemTotalVC;
        address token;
    }

    // --- Variable container structs  ---
    struct AdjustTrove_Params {
        address[] _collsIn;
        uint256[] _amountsIn;
        address[] _collsOut;
        uint256[] _amountsOut;
        uint256[] _maxSlippages;
        uint256 _USMChange;
        uint256 _totalUSMDebtFromLever;
        bool _isDebtIncrease;
        bool _isUnlever;
        address _upperHint;
        address _lowerHint;
        uint256 _maxFeePercentage;
    }

    struct LocalVariables_adjustTrove {
        uint256 netDebtChange;
        bool isCollIncrease;
        uint256 collChange;
        uint256 currVC;
        uint256 newVC;
        uint256 debt;
        address[] currAssets;
        uint256[] currAmounts;
        address[] newAssets;
        uint256[] newAmounts;
        uint256 oldICR;
        uint256 newICR;
        uint256 newTCR;
        uint256 USMFee;
        uint256 variableUSMFee;
        uint256 newDebt;
        uint256 VCin;
        uint256 VCout;
        uint256 maxFeePercentageFactor;
    }

    struct LocalVariables_openTrove {
        address[] collaterals;
        uint256[] prices;
        uint256 USMFee;
        uint256 netDebt;
        uint256 compositeDebt;
        uint256 ICR;
        uint256 arrayIndex;
        address collAddress;
        uint256 VC;
        uint256 newTCR;
        bool isRecoveryMode;
    }

    struct CloseTrove_Params {
        address[] _collsOut;
        uint256[] _amountsOut;
        uint256[] _maxSlippages;
        bool _isUnlever;
    }

    struct ContractsCache {
        ITroveManager troveManager;
        IActivePool activePool;
        IUSMToken usmToken;
    }

    enum BorrowerOperation {
        openTrove,
        closeTrove,
        adjustTrove
    }

    // ========"Diamond Storage"========
    struct DiamondStorage {
        // maps function selector to the facet address and
        // the position of the selector in the facetFunctionSelectors.selectors array
        mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
        // maps facet addresses to function selectors
        mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
        // facet addresses
        address[] facetAddresses;
        // owner of the contract
        address contractOwner;
        // paused of the contract
        bool _paused;
        // chainId
        uint256 chainId;
        //==== addresses
        AllAddresses allAddresses;
        AllAddresses2 allAddresses2;
        //==== interfaces
        IWhitelist whitelist;
        IActivePool activePool;
        IDefaultPool defaultPool;
        // IStabilityPool stabilityPool;
        ICollSurplusPool collSurplusPool;
        ITroveManager troveManager;
        // A doubly linked list of Troves, sorted by their collateral ratios
        ISortedTroves sortedTroves;
        IUSMToken usmToken;
        ISMOJO sMOJO;
        IBorrowerOperations borrowerOperations;
        // status of addresses set
        bool addressesSet;
        //=== deposited collateral tracker of each pool. Colls is always the whitelisted list of all collateral tokens.
        newColls apoolColl;
        newColls dpoolColl;
        // newColls spoolColl;
        //=== USM Debt tracker. Tracker of all debt in the system (active + default + stability).
        // NOTE: For each pool, there is a separate state variable defined for tracking the Debt (active, closed).
        uint256 aUSMDebt; // USM debt of active pool
        uint256 dUSMDebt; // USM debt of default pool
        // uint256 sUSMDebt; // USM debt of stability pool

        mapping(address => CollateralParams) collateralParams;
        mapping(address => bool) validRouter;
        // list of all collateral types in collateralParams (active and deprecated)
        // Addresses for easy access
        address[] validCollateral; // index maps to token address.
        uint256 deploymentTime; // deployment time for "BorrowerOperations.sol"

        // TODO: Please add new members from end of struct
    }

    uint256 internal constant BOOTSTRAP_PERIOD = 14 days;

    uint256 internal constant DECIMAL_PRECISION = 1e18;
    uint256 internal constant HALF_DECIMAL_PRECISION = 5e17;

    uint256 public constant _100pct = 1e18; // 1e18 == 100%

    uint256 public constant _110pct = 11e17; // 1.1e18 == 110%

    // Minimum collateral ratio for individual troves
    uint256 public constant MCR = 11e17; // 110%

    // Critical system collateral ratio. If the system's total collateral ratio (TCR) falls below the CCR, Recovery Mode is triggered.
    uint256 public constant CCR = 15e17; // 150%

    // Amount of USM to be locked in gas pool on opening troves
    uint256 public constant USM_GAS_COMPENSATION = 200e18;

    // Minimum amount of net USM debt a must have
    uint256 public constant MIN_NET_DEBT = 1800e18;
    // uint256 constant public MIN_NET_DEBT = 0;

    uint256 public constant PERCENT_DIVISOR = 200; // dividing by 200 yields 0.5%

    uint256 public constant BORROWING_FEE_FLOOR =
        (DECIMAL_PRECISION / 1000) * 5; // 0.5%
    uint256 public constant REDEMPTION_FEE_FLOOR =
        (DECIMAL_PRECISION / 1000) * 5; // 0.5%

    function diamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    function setContractOwner(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }

    function checkContractOwner() internal view {
        require(msg.sender == diamondStorage().contractOwner, "LIBE0");
    }

    // The contract must be paused.
    function whenPaused() internal view {
        require(diamondStorage()._paused, "LIBE1");
    }

    // The contract must not be paused.
    function whenNotPaused() internal view {
        require(!diamondStorage()._paused, "LIBE2");
    }

    event DiamondCut(
        IDiamondCut.FacetCut[] _diamondCut,
        address _init,
        bytes _calldata
    );

    // Internal function version of diamondCut
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        for (
            uint256 facetIndex;
            facetIndex < _diamondCut.length;
            facetIndex++
        ) {
            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == IDiamondCut.FacetCutAction.Add) {
                addFunctions(
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].functionSelectors
                );
            } else if (action == IDiamondCut.FacetCutAction.Replace) {
                replaceFunctions(
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].functionSelectors
                );
            } else if (action == IDiamondCut.FacetCutAction.Remove) {
                removeFunctions(
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].functionSelectors
                );
            } else {
                revert("LIBE3");
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        require(_functionSelectors.length > 0, "LIBE4");
        DiamondStorage storage ds = diamondStorage();
        require(_facetAddress != address(0), "LIBE5");
        uint96 selectorPosition = uint96(
            ds.facetFunctionSelectors[_facetAddress].functionSelectors.length
        );
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds
                .selectorToFacetAndPosition[selector]
                .facetAddress;
            require(oldFacetAddress == address(0), "LIBE6");
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function replaceFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        require(_functionSelectors.length > 0, "LIBE4");
        DiamondStorage storage ds = diamondStorage();
        require(_facetAddress != address(0), "LIBE5");
        uint96 selectorPosition = uint96(
            ds.facetFunctionSelectors[_facetAddress].functionSelectors.length
        );
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds
                .selectorToFacetAndPosition[selector]
                .facetAddress;
            require(
                oldFacetAddress != _facetAddress,
                "LibDiamond: SAME_FUNCTION"
            );
            removeFunction(ds, oldFacetAddress, selector);
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function removeFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        require(_functionSelectors.length > 0, "LIBE4");
        DiamondStorage storage ds = diamondStorage();
        // if function does not exist then do nothing and return
        require(_facetAddress == address(0), "LIBE5");
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds
                .selectorToFacetAndPosition[selector]
                .facetAddress;
            removeFunction(ds, oldFacetAddress, selector);
        }
    }

    function addFacet(DiamondStorage storage ds, address _facetAddress)
        internal
    {
        enforceHasContractCode(_facetAddress, "LIBE7");
        ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = ds
            .facetAddresses
            .length;
        ds.facetAddresses.push(_facetAddress);
    }

    function addFunction(
        DiamondStorage storage ds,
        bytes4 _selector,
        uint96 _selectorPosition,
        address _facetAddress
    ) internal {
        ds
            .selectorToFacetAndPosition[_selector]
            .functionSelectorPosition = _selectorPosition;
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(
            _selector
        );
        ds.selectorToFacetAndPosition[_selector].facetAddress = _facetAddress;
    }

    function removeFunction(
        DiamondStorage storage ds,
        address _facetAddress,
        bytes4 _selector
    ) internal {
        require(_facetAddress != address(0), "LIBE8");
        // an immutable function is a function defined directly in a diamond
        require(_facetAddress != address(this), "LIBE9");
        // replace selector with last selector, then delete last selector
        uint256 selectorPosition = ds
            .selectorToFacetAndPosition[_selector]
            .functionSelectorPosition;
        uint256 lastSelectorPosition = ds
            .facetFunctionSelectors[_facetAddress]
            .functionSelectors
            .length - 1;
        // if not the same then replace _selector with lastSelector
        if (selectorPosition != lastSelectorPosition) {
            bytes4 lastSelector = ds
                .facetFunctionSelectors[_facetAddress]
                .functionSelectors[lastSelectorPosition];
            ds.facetFunctionSelectors[_facetAddress].functionSelectors[
                    selectorPosition
                ] = lastSelector;
            ds
                .selectorToFacetAndPosition[lastSelector]
                .functionSelectorPosition = uint96(selectorPosition);
        }
        // delete the last selector
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.pop();
        delete ds.selectorToFacetAndPosition[_selector];

        // if no more selectors for facet address then delete the facet address
        if (lastSelectorPosition == 0) {
            // replace facet address with last facet address and delete last facet address
            uint256 lastFacetAddressPosition = ds.facetAddresses.length - 1;
            uint256 facetAddressPosition = ds
                .facetFunctionSelectors[_facetAddress]
                .facetAddressPosition;
            if (facetAddressPosition != lastFacetAddressPosition) {
                address lastFacetAddress = ds.facetAddresses[
                    lastFacetAddressPosition
                ];
                ds.facetAddresses[facetAddressPosition] = lastFacetAddress;
                ds
                    .facetFunctionSelectors[lastFacetAddress]
                    .facetAddressPosition = facetAddressPosition;
            }
            ds.facetAddresses.pop();
            delete ds
                .facetFunctionSelectors[_facetAddress]
                .facetAddressPosition;
        }
    }

    function initializeDiamondCut(address _init, bytes memory _calldata)
        internal
    {
        if (_init == address(0)) {
            require(_calldata.length == 0, "LIBE10");
        } else {
            require(_calldata.length > 0, "LIBE11");
            if (_init != address(this)) {
                enforceHasContractCode(_init, "LIBE12");
            }
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (!success) {
                if (error.length > 0) {
                    // bubble up the error
                    revert(string(error));
                } else {
                    revert("LIBE13");
                }
            }
        }
    }

    function enforceHasContractCode(
        address _contract,
        string memory _errorMessage
    ) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }

    /**
     * ****************************************
     *
     * Modifiers
     * ****************************************
     */

    // --- 'require' functions | "ActivePool.sol" | "DefaultPool.sol"---

    function _requireCallerIsBOorTroveMorTMLorSP() internal view {
        DiamondStorage storage ds = diamondStorage();

        if (
            msg.sender != ds.allAddresses2.borrowerOperationsAddress &&
            msg.sender != ds.allAddresses2.troveManagerAddress &&
            // msg.sender != ds.allAddresses.stabilityPoolAddress &&
            msg.sender != ds.allAddresses2.troveManagerLiquidationsAddress &&
            msg.sender != ds.allAddresses2.troveManagerRedemptionsAddress
        ) {
            _revertWrongFuncCaller();
        }
    }

    function _requireCallerIsBorrowerOperationsOrDefaultPool() internal view {
        DiamondStorage storage ds = diamondStorage();

        if (
            msg.sender != ds.allAddresses2.borrowerOperationsAddress &&
            msg.sender != ds.allAddresses.defaultPoolAddress
        ) {
            _revertWrongFuncCaller();
        }
    }

    function _requireCallerIsBorrowerOperations() internal view {
        DiamondStorage storage ds = diamondStorage();

        if (msg.sender != ds.allAddresses2.borrowerOperationsAddress) {
            _revertWrongFuncCaller();
        }
    }

    function _requireCallerIsBOorTroveMorSP() internal view {
        DiamondStorage storage ds = diamondStorage();

        if (
            msg.sender != ds.allAddresses2.borrowerOperationsAddress &&
            msg.sender != ds.allAddresses2.troveManagerAddress &&
            // msg.sender != ds.allAddresses.stabilityPoolAddress &&
            msg.sender != ds.allAddresses2.troveManagerRedemptionsAddress
        ) {
            _revertWrongFuncCaller();
        }
    }

    function _requireCallerIsBOorTroveM() internal view {
        DiamondStorage storage ds = diamondStorage();

        if (
            msg.sender != ds.allAddresses2.borrowerOperationsAddress &&
            msg.sender != ds.allAddresses2.troveManagerAddress
        ) {
            _revertWrongFuncCaller();
        }
    }

    function _requireCallerIsTroveManager() internal view {
        LibMojoDiamond.DiamondStorage storage ds = LibMojoDiamond
            .diamondStorage();

        if (msg.sender != ds.allAddresses2.troveManagerAddress) {
            _revertWrongFuncCaller();
        }
    }

    function _requireCallerIsWhitelist() internal view {
        DiamondStorage storage ds = diamondStorage();

        if (msg.sender != address(ds.whitelist)) {
            _revertWrongFuncCaller();
        }
    }

    function _requireCallerIsActivePool() internal view {
        DiamondStorage storage ds = diamondStorage();

        if (msg.sender != ds.allAddresses.activePoolAddress) {
            _revertWrongFuncCaller();
        }
    }

    function _revertWrongFuncCaller() internal pure {
        revert("AP: External caller not allowed");
    }

    // --- BorrowerOperations Facet: 'Require' wrapper functions ---

    function _requireValidDepositCollateral(
        address[] memory _colls,
        uint256[] memory _amounts
    ) internal view {
        uint256 collsLen = _colls.length;
        _requireLengthsEqual(collsLen, _amounts.length);
        for (uint256 i; i < collsLen; ++i) {
            require(
                LibMojoDiamond.diamondStorage().whitelist.getIsActive(
                    _colls[i]
                ),
                "BO:BadColl"
            );
            require(_amounts[i] != 0, "BO:NoAmounts");
        }
    }

    function _requireNonZeroAdjustment(
        uint256[] memory _amountsIn,
        uint256[] memory _amountsOut,
        uint256 _USMChange
    ) internal pure {
        require(
            _arrayIsNonzero(_amountsIn) ||
                _arrayIsNonzero(_amountsOut) ||
                _USMChange != 0,
            "BO:0Adjust"
        );
    }

    function _arrayIsNonzero(uint256[] memory arr)
        internal
        pure
        returns (bool)
    {
        uint256 arrLen = arr.length;
        for (uint256 i; i < arrLen; ++i) {
            if (arr[i] != 0) {
                return true;
            }
        }
        return false;
    }

    function _isBeforeFeeBootstrapPeriod() internal view returns (bool) {
        LibMojoDiamond.DiamondStorage storage ds = LibMojoDiamond
            .diamondStorage();
        return
            block.timestamp <
            ds.deploymentTime + LibMojoDiamond.BOOTSTRAP_PERIOD; // won't overflow
    }

    function _requireTroveisActive(
        ITroveManager _troveManager,
        address _borrower
    ) internal view {
        require(_troveManager.isTroveActive(_borrower), "BO:TroveInactive");
    }

    function _requireTroveisNotActive(
        ITroveManager _troveManager,
        address _borrower
    ) internal view {
        require(!_troveManager.isTroveActive(_borrower), "BO:TroveActive");
    }

    function _requireNonZeroDebtChange(uint256 _USMChange) internal pure {
        require(_USMChange != 0, "BO:NoDebtChange");
    }

    function _requireNoOverlapColls(
        address[] calldata _colls1,
        address[] calldata _colls2
    ) internal pure {
        uint256 colls1Len = _colls1.length;
        uint256 colls2Len = _colls2.length;
        for (uint256 i; i < colls1Len; ++i) {
            for (uint256 j; j < colls2Len; j++) {
                require(_colls1[i] != _colls2[j], "BO:OverlapColls");
            }
        }
    }

    function _requireNoDuplicateColls(address[] memory _colls) internal pure {
        uint256 collsLen = _colls.length;
        for (uint256 i; i < collsLen; ++i) {
            for (uint256 j = (i + 1); j < collsLen; j++) {
                require(_colls[i] != _colls[j], "BO:OverlapColls");
            }
        }
    }

    // As recovery mode is disabled which implies there will be always normal mode or not.
    // function _requireNotInRecoveryMode() internal view {
    //     require(!_checkRecoveryMode(), "BO:InRecMode");
    // }

    function _requireNoCollWithdrawal(uint256[] memory _amountOut)
        internal
        pure
    {
        require(!_arrayIsNonzero(_amountOut), "BO:InRecMode");
    }

    // Function require length nonzero, used to save contract size on revert strings.
    function _requireLengthNonzero(uint256 length) internal pure {
        require(length != 0, "BOps:Len0");
    }

    // Function require length equal, used to save contract size on revert strings.
    function _requireLengthsEqual(uint256 length1, uint256 length2)
        internal
        pure
    {
        require(length1 == length2, "BO:LenMismatch");
    }

    function _requireICRisAboveMCR(uint256 _newICR) internal pure {
        require(_newICR >= LibMojoDiamond.MCR, "BO:ReqICR>MCR");
    }

    function _requireICRisAboveCCR(uint256 _newICR) internal pure {
        require(_newICR >= LibMojoDiamond.CCR, "BO:ReqICR>CCR");
    }

    function _requireNewICRisAboveOldICR(uint256 _newICR, uint256 _oldICR)
        internal
        pure
    {
        require(_newICR >= _oldICR, "BO:RecMode:ICR<oldICR");
    }

    function _requireNewTCRisAboveCCR(uint256 _newTCR) internal pure {
        require(_newTCR >= LibMojoDiamond.CCR, "BO:ReqTCR>CCR");
    }

    function _requireAtLeastMinNetDebt(uint256 _netDebt) internal pure {
        require(_netDebt >= LibMojoDiamond.MIN_NET_DEBT, "BO:netDebt<2000");
    }

    function _requireValidUSMRepayment(
        uint256 _currentDebt,
        uint256 _debtRepayment
    ) internal pure {
        require(
            _debtRepayment <=
                (_currentDebt - LibMojoDiamond.USM_GAS_COMPENSATION),
            "BO:InvalidUSMRepay"
        );
    }

    function _requireSufficientUSMBalance(
        IUSMToken _usmToken,
        address _borrower,
        uint256 _debtRepayment
    ) internal view {
        require(
            _usmToken.balanceOf(_borrower) >= _debtRepayment,
            "BO:InsuffUSMBal"
        );
    }

    // function _requireValidMaxFeePercentage(uint256 _maxFeePercentage, bool _isRecoveryMode)
    //     internal
    //     pure
    // {
    //     // Always require max fee to be less than 100%, and if not in recovery mode then max fee must be greater than 0.5%
    //     if (_maxFeePercentage > DECIMAL_PRECISION || (!_isRecoveryMode && _maxFeePercentage < BORROWING_FEE_FLOOR)) {
    //         revert("BO:InvalidMaxFee");
    //     }
    // }

    function _requireValidMaxFeePercentage(uint256 _maxFeePercentage)
        internal
        pure
    {
        // Always require max fee to be less than 100%, and if not in recovery mode then max fee must be greater than 0.5%
        if (
            _maxFeePercentage > LibMojoDiamond.DECIMAL_PRECISION ||
            _maxFeePercentage < LibMojoDiamond.BORROWING_FEE_FLOOR
        ) {
            revert("BO:InvalidMaxFee");
        }
    }

    // checks lengths are all good and that all passed in routers are valid routers
    // function _requireValidRouterParams(
    //     address[] memory _finalRoutedColls,
    //     uint256[] memory _amounts,
    //     uint256[] memory _minSwapAmounts,
    //     IYetiRouter[] memory _routers) internal view {
    //     require(_finalRoutedColls.length == _amounts.length,  "_requireValidRouterParams: _finalRoutedColls length mismatch");
    //     require(_amounts.length == _routers.length, "_requireValidRouterParams: _routers length mismatch");
    //     require(_amounts.length == _minSwapAmounts.length, "_minSwapAmounts: finalRoutedColls length mismatch");
    //     for (uint256 i; i < _routers.length; ++i) {
    //         require(whitelist.isValidRouter(address(_routers[i])), "_requireValidRouterParams: not a valid router");
    //     }
    // }

    // // requires that avax indices are in order
    // function _requireRouterAVAXIndicesInOrder(uint256[] memory _indices) internal pure {
    //     for (uint256 i; i < _indices.length - 1; ++i) {
    //         require(_indices[i] < _indices[i + 1], "_requireRouterAVAXIndicesInOrder: indices out of order");
    //     }
    // }
}
