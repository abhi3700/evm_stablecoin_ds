// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "../interfaces/IBorrowerOperations.sol";
import "../interfaces/ITroveManager.sol";
import "../interfaces/IUSMToken.sol";
import "../interfaces/ICollSurplusPool.sol";
import "../interfaces/ISortedTroves.sol";
import "../interfaces/ISMOJO.sol";
import "../interfaces/IWhitelist.sol";
import "../interfaces/IYetiRouter.sol"; // TODO
import "../interfaces/IERC20.sol";
import "../dependencies/LiquityBase.sol";
// import "../dependencies/SafeMath.sol";
import "../dependencies/ReentrancyGuard.sol";
import "../interfaces/IWAsset.sol";
import "../libs/LibMojoDiamond.sol";

/**
 * BorrowerOperations is the contract that handles most of external facing trove activities that
 * a user would make with their own trove, like opening, closing, adjusting, increasing leverage, etc.
 */

/**
   A summary of Lever Up:
   Takes in a collateral token A, and simulates borrowing of USM at a certain collateral ratio and
   buying more token A, putting back into protocol, buying more A, etc. at a certain leverage amount.
   So if at 3x leverage and 1000$ token A, it will mint 1000 * 3x * 2/3 = $2000 USM, then swap for
   token A by using some router strategy, returning a little under $2000 token A to put back in the
   trove. The number here is 2/3 because the math works out to be that collateral ratio is 150% if
   we have a 3x leverage. They now have a trove with $3000 of token A and a collateral ratio of 150%.
  */

contract BorrowerOperations is
    LiquityBase,
    CheckContract,
    IBorrowerOperations,
    ReentrancyGuard
{
    // using SafeMath for uint256;
    // string public constant NAME = "BorrowerOperations";

    // --- Connected contract declarations ---

    // ITroveManager internal troveManager;

    // address internal stabilityPoolAddress;

    // address internal gasPoolAddress;

    // ICollSurplusPool internal collSurplusPool;

    // ISMOJO internal sMOJO;
    // address internal sMOJOAddress;

    // IUSMToken internal usmToken;

    // uint internal constant BOOTSTRAP_PERIOD = 14 days;
    // uint deploymentTime;

    // A doubly linked list of Troves, sorted by their collateral ratios
    // ISortedTroves internal sortedTroves;

    // struct CollateralData {
    //     address collateral;
    //     uint256 amount;
    // }

    // struct DepositFeeCalc {
    //     uint256 collateralUSMFee;
    //     uint256 systemCollateralVC;
    //     uint256 collateralInputVC;
    //     uint256 systemTotalVC;
    //     address token;
    // }

    /* --- Variable container structs  ---

    Used to hold, return and assign variables inside a function, in order to avoid the error:
    "CompilerError: Stack too deep". */
    // struct AdjustTrove_Params {
    //     address[] _collsIn;
    //     uint256[] _amountsIn;
    //     address[] _collsOut;
    //     uint256[] _amountsOut;
    //     uint256[] _maxSlippages;
    //     uint256 _USMChange;
    //     uint256 _totalUSMDebtFromLever;
    //     bool _isDebtIncrease;
    //     bool _isUnlever;
    //     address _upperHint;
    //     address _lowerHint;
    //     uint256 _maxFeePercentage;
    // }

    // struct LocalVariables_adjustTrove {
    //     uint256 netDebtChange;
    //     bool isCollIncrease;
    //     uint256 collChange;
    //     uint256 currVC;
    //     uint256 newVC;
    //     uint256 debt;
    //     address[] currAssets;
    //     uint256[] currAmounts;
    //     address[] newAssets;
    //     uint256[] newAmounts;
    //     uint256 oldICR;
    //     uint256 newICR;
    //     uint256 newTCR;
    //     uint256 USMFee;
    //     uint256 variableUSMFee;
    //     uint256 newDebt;
    //     uint256 VCin;
    //     uint256 VCout;
    //     uint256 maxFeePercentageFactor;
    // }

    // struct LocalVariables_openTrove {
    //     address[] collaterals;
    //     uint256[] prices;
    //     uint256 USMFee;
    //     uint256 netDebt;
    //     uint256 compositeDebt;
    //     uint256 ICR;
    //     uint256 arrayIndex;
    //     address collAddress;
    //     uint256 VC;
    //     uint256 newTCR;
    //     bool isRecoveryMode;
    // }

    // struct CloseTrove_Params {
    //     address[] _collsOut;
    //     uint256[] _amountsOut;
    //     uint256[] _maxSlippages;
    //     bool _isUnlever;
    // }

    // struct ContractsCache {
    //     ITroveManager troveManager;
    //     IActivePool activePool;
    //     IUSMToken usmToken;
    // }

    // enum BorrowerOperation {
    //     openTrove,
    //     closeTrove,
    //     adjustTrove
    // }

    // event TroveManagerAddressChanged(address _newTroveManagerAddress);
    // event ActivePoolAddressChanged(address _activePoolAddress);
    // event DefaultPoolAddressChanged(address _defaultPoolAddress);
    // event StabilityPoolAddressChanged(address _stabilityPoolAddress);
    // event GasPoolAddressChanged(address _gasPoolAddress);
    // event CollSurplusPoolAddressChanged(address _collSurplusPoolAddress);
    // event PriceFeedAddressChanged(address _newPriceFeedAddress);
    // event SortedTrovesAddressChanged(address _sortedTrovesAddress);
    // event USMTokenAddressChanged(address _usmTokenAddress);
    // event sMOJOAddressChanged(address _sMOJOAddress);

    event TroveCreated(address indexed _borrower, uint256 arrayIndex);
    event TroveUpdated(
        address indexed _borrower,
        uint256 _debt,
        address[] _tokens,
        uint256[] _amounts,
        BorrowerOperation operation
    );
    event USMBorrowingFeePaid(address indexed _borrower, uint256 _USMFee);

    // --- Dependency setters ---

    // function setAddresses(
    //     address _troveManagerAddress,
    //     address _activePoolAddress,
    //     address _defaultPoolAddress,
    //     address _stabilityPoolAddress,
    //     address _gasPoolAddress,
    //     address _collSurplusPoolAddress,
    //     address _sortedTrovesAddress,
    //     address _usmTokenAddress,
    //     address _sMOJOAddress,
    //     address _whitelistAddress
    // ) external override onlyOwner {
    //     // This makes impossible to open a trove with zero withdrawn USM
    //     require(LibMojoDiamond.MIN_NET_DEBT != 0, "BO:MIN_NET_DEBT==0");

    //     LibMojoDiamond.DiamondStorage storage ds = LibMojoDiamond
    //         .diamondStorage();

    //     ds.deploymentTime = block.timestamp;

    //     checkContract(_troveManagerAddress);
    //     checkContract(_activePoolAddress);
    //     checkContract(_defaultPoolAddress);
    //     checkContract(_stabilityPoolAddress);
    //     checkContract(_gasPoolAddress);
    //     checkContract(_collSurplusPoolAddress);
    //     checkContract(_sortedTrovesAddress);
    //     checkContract(_usmTokenAddress);
    //     checkContract(_sMOJOAddress);
    //     checkContract(_whitelistAddress);

    //     ds.troveManager = ITroveManager(_troveManagerAddress);
    //     ds.activePool = IActivePool(_activePoolAddress);
    //     ds.defaultPool = IDefaultPool(_defaultPoolAddress);
    //     ds.whitelist = IWhitelist(_whitelistAddress);
    //     // stabilityPoolAddress = _stabilityPoolAddress;
    //     ds.gasPoolAddress = _gasPoolAddress;
    //     ds.collSurplusPool = ICollSurplusPool(_collSurplusPoolAddress);
    //     ds.sortedTroves = ISortedTroves(_sortedTrovesAddress);
    //     ds.usmToken = IUSMToken(_usmTokenAddress);
    //     ds.sMOJOAddress = _sMOJOAddress;

    //     emit TroveManagerAddressChanged(_troveManagerAddress);
    //     emit ActivePoolAddressChanged(_activePoolAddress);
    //     emit DefaultPoolAddressChanged(_defaultPoolAddress);
    //     // emit StabilityPoolAddressChanged(_stabilityPoolAddress);
    //     emit GasPoolAddressChanged(_gasPoolAddress);
    //     emit CollSurplusPoolAddressChanged(_collSurplusPoolAddress);
    //     emit SortedTrovesAddressChanged(_sortedTrovesAddress);
    //     emit USMTokenAddressChanged(_usmTokenAddress);
    //     emit sMOJOAddressChanged(_sMOJOAddress);

    //     // In MojoFi, we aim at upgradeability functionality, so the deployer must be owner
    //     // & the decision is taken based on DAO voting
    //     // _renounceOwnership();
    // }

    // --- Borrower Trove Operations ---

    function openTrove(
        uint256 _maxFeePercentage,
        uint256 _USMAmount,
        address _upperHint,
        address _lowerHint,
        address[] calldata _colls,
        uint256[] calldata _amounts
    ) external override nonReentrant {
        _requireLengthNonzero(_amounts.length);
        _requireValidDepositCollateral(_colls, _amounts);
        _requireNoDuplicateColls(_colls); // Check that there is no overlap in _colls

        // transfer collateral into ActivePool
        _transferCollateralsIntoActivePool(msg.sender, _colls, _amounts);

        _openTroveInternal(
            msg.sender,
            _maxFeePercentage,
            _USMAmount,
            0,
            _upperHint,
            _lowerHint,
            _colls,
            _amounts
        );
    }

    // Lever up. Takes in a leverage amount (11x) and a token, and calculates the amount
    // of that token that would be at the specific collateralization ratio. Mints USM
    // according to the price of the token and the amount. Calls LeverUp.sol's
    // function to perform the swap through a router or our special staked tokens, depending
    // on the token. Then opens a trove with the new collateral from the swap, ensuring that
    // the amount is enough to cover the debt. There is no new debt taken out from the trove,
    // and the amount minted previously is attributed to this trove. Reverts if the swap was
    // not able to get the correct amount of collateral according to slippage passed in.
    // _leverage is like 11e18 for 11x.
    function openTroveLeverUp(
        uint256 _maxFeePercentage,
        uint256 _USMAmount,
        address _upperHint,
        address _lowerHint,
        address[] memory _colls,
        uint256[] memory _amounts,
        uint256[] memory _leverages,
        uint256[] calldata _maxSlippages
    ) external override nonReentrant {
        uint256 collsLen = _colls.length;
        _requireLengthNonzero(collsLen);
        _requireValidDepositCollateral(_colls, _amounts);
        // Must check additional passed in arrays
        _requireLengthsEqual(collsLen, _leverages.length);
        _requireLengthsEqual(collsLen, _maxSlippages.length);
        _requireNoDuplicateColls(_colls);
        uint additionalTokenAmount;
        uint additionalUSMDebt;
        uint totalUSMDebtFromLever;
        for (uint256 i; i < collsLen; ++i) {
            if (_leverages[i] != 0) {
                (additionalTokenAmount, additionalUSMDebt) = _singleLeverUp(
                    _colls[i],
                    _amounts[i],
                    _leverages[i],
                    _maxSlippages[i]
                );
                // Transfer into active pool, non levered amount.
                _singleTransferCollateralIntoActivePool(
                    msg.sender,
                    _colls[i],
                    _amounts[i]
                );
                // additional token amount was set to the original amount * leverage.
                _amounts[i] += additionalTokenAmount;
                totalUSMDebtFromLever += additionalUSMDebt;
            } else {
                // Otherwise skip and do normal transfer that amount into active pool.
                _singleTransferCollateralIntoActivePool(
                    msg.sender,
                    _colls[i],
                    _amounts[i]
                );
            }
        }
        _USMAmount = _USMAmount.add(totalUSMDebtFromLever);

        _openTroveInternal(
            msg.sender,
            _maxFeePercentage,
            _USMAmount,
            totalUSMDebtFromLever,
            _upperHint,
            _lowerHint,
            _colls,
            _amounts
        );
    }

    // internal function for minting USM at certain leverage and max slippage, and then performing
    // swap with whitelist's approved router.
    function _singleLeverUp(
        address _token,
        uint256 _amount,
        uint256 _leverage,
        uint256 _maxSlippage
    ) internal returns (uint256 _finalTokenAmount, uint256 _additionalUSMDebt) {
        require(_leverage > 1e18, "WrongLeverage");
        require(_maxSlippage <= 1e18, "WrongSlippage");
        // TODO: modify IYetiRouter --> IMojoRouter
        IYetiRouter router = IYetiRouter(
            whitelist.getDefaultRouterAddress(_token)
        );
        // leverage is 5e18 for 5x leverage. Minus 1 for what the user already has in collateral value.
        uint _additionalTokenAmount = (_amount * (_leverage - 1e18)) / 1e18;
        _additionalUSMDebt = whitelist.getValueUSD(
            _token,
            _additionalTokenAmount
        );

        // 1/(1-1/ICR) = leverage. (1 - 1/ICR) = 1/leverage
        // 1 - 1/leverage = 1/ICR. ICR = 1/(1 - 1/leverage) = (1/((leverage-1)/leverage)) = leverage / (leverage - 1)
        // ICR = leverage / (leverage - 1)

        // ICR = VC value of collateral / debt
        // debt = VC value of collateral / ICR.
        // debt = VC value of collateral * (leverage - 1) / leverage

        uint256 slippageAdjustedValue = _additionalTokenAmount
            .mul(LibMojoDiamond.DECIMAL_PRECISION.sub(_maxSlippage))
            .div(1e18);
        LibMojoDiamond.DiamondStorage storage ds = LibMojoDiamond
            .diamondStorage();

        ds.usmToken.mint(address(this), _additionalUSMDebt);
        ds.usmToken.approve(address(router), _additionalUSMDebt);
        // route will swap the tokens and transfer it to the active pool automatically. Router will send to active pool and
        // reward balance will be sent to the user if wrapped asset.
        IERC20 erc20Token = IERC20(_token);
        uint256 balanceBefore = erc20Token.balanceOf(address(ds.activePool));
        _finalTokenAmount = router.route(
            address(this),
            address(ds.usmToken),
            _token,
            _additionalUSMDebt,
            slippageAdjustedValue
        );
        require(
            erc20Token.balanceOf(address(ds.activePool)) ==
                balanceBefore.add(_finalTokenAmount),
            "BO:RouteLeverUpNotSent"
        );
    }

    // amounts should be a uint array giving the amount of each collateral
    // to be transferred in order of the current whitelist
    // Should be called *after* collateral has been already sent to the active pool
    // Should confirm _colls, is valid collateral prior to calling this
    function _openTroveInternal(
        address _troveOwner,
        uint256 _maxFeePercentage,
        uint256 _USMAmount,
        uint256 _totalUSMDebtFromLever,
        address _upperHint,
        address _lowerHint,
        address[] memory _colls,
        uint256[] memory _amounts
    ) internal {
        LocalVariables_openTrove memory vars;

        // vars.isRecoveryMode = _checkRecoveryMode();      // NOTE: disabled recovery mode

        LibMojoDiamond.ContractsCache memory contractsCache = LibMojoDiamond
            .ContractsCache(troveManager, activePool, usmToken);

        _requireValidMaxFeePercentage(_maxFeePercentage);
        _requireTroveisNotActive(contractsCache.troveManager, _troveOwner);

        vars.netDebt = _USMAmount;

        // For every collateral type in, calculate the VC and get the variable fee
        vars.VC = _getVC(_colls, _amounts);

        // if (!vars.isRecoveryMode) {
        //     // when not in recovery mode, add in the 0.5% fee
        //     vars.USMFee = _triggerBorrowingFee(
        //         contractsCache.troveManager,
        //         contractsCache.usmToken,
        //         _USMAmount,
        //         vars.VC, // here it is just VC in, which is always larger than USM amount
        //         _maxFeePercentage
        //     );
        //     _maxFeePercentage = _maxFeePercentage.sub(vars.USMFee.mul(DECIMAL_PRECISION).div(vars.VC));
        // }

        // when not in recovery mode, add in the 0.5% fee
        vars.USMFee = _triggerBorrowingFee(
            contractsCache.troveManager,
            contractsCache.usmToken,
            _USMAmount,
            vars.VC, // here it is just VC in, which is always larger than USM amount
            _maxFeePercentage
        );
        _maxFeePercentage = _maxFeePercentage.sub(
            vars.USMFee.mul(DECIMAL_PRECISION).div(vars.VC)
        );

        // Add in variable fee. Always present, even in recovery mode.
        vars.USMFee = vars.USMFee.add(
            _getTotalVariableDepositFee(
                _colls,
                _amounts,
                vars.VC,
                0,
                vars.VC,
                _maxFeePercentage,
                contractsCache
            )
        );

        // Adds total fees to netDebt
        vars.netDebt = vars.netDebt.add(vars.USMFee); // The raw debt change includes the fee

        _requireAtLeastMinNetDebt(vars.netDebt);
        // ICR is based on the composite debt, i.e. the requested USM amount + USM borrowing fee + USM gas comp.
        // _getCompositeDebt returns  vars.netDebt + USM gas comp.
        vars.compositeDebt = _getCompositeDebt(vars.netDebt);

        vars.ICR = LiquityMath._computeCR(vars.VC, vars.compositeDebt);
        // if (vars.isRecoveryMode) {
        //     _requireICRisAboveCCR(vars.ICR);        // ICR > CCR
        // } else {
        //     _requireICRisAboveMCR(vars.ICR);        // ICR > MCR
        //     vars.newTCR = _getNewTCRFromTroveChange(vars.VC, true, vars.compositeDebt, true); // bools: coll increase, debt increase
        //     _requireNewTCRisAboveCCR(vars.newTCR);  // new_TCR > CCR
        // }

        // when not in Recovery mode
        _requireICRisAboveMCR(vars.ICR); // ICR > MCR
        vars.newTCR = _getNewTCRFromTroveChange(
            vars.VC,
            true,
            vars.compositeDebt,
            true
        ); // bools: coll increase, debt increase
        _requireNewTCRisAboveCCR(vars.newTCR); // new_TCR > CCR

        // Set the trove struct's properties
        contractsCache.troveManager.setTroveStatus(_troveOwner, 1);

        contractsCache.troveManager.updateTroveColl(
            _troveOwner,
            _colls,
            _amounts
        );
        contractsCache.troveManager.increaseTroveDebt(
            _troveOwner,
            vars.compositeDebt
        );

        contractsCache.troveManager.updateTroveRewardSnapshots(_troveOwner);

        contractsCache.troveManager.updateStakeAndTotalStakes(_troveOwner);

        LibMojoDiamond.DiamondStorage storage ds = LibMojoDiamond
            .diamondStorage();

        ds.sortedTroves.insert(_troveOwner, vars.ICR, _upperHint, _lowerHint);
        vars.arrayIndex = contractsCache.troveManager.addTroveOwnerToArray(
            _troveOwner
        );
        emit TroveCreated(_troveOwner, vars.arrayIndex);

        contractsCache.activePool.receiveCollateral(_colls, _amounts);

        _withdrawUSM(
            contractsCache.activePool,
            contractsCache.usmToken,
            _troveOwner,
            _USMAmount.sub(_totalUSMDebtFromLever),
            vars.netDebt
        );

        // Move the USM gas compensation to the Gas Pool
        _withdrawUSM(
            contractsCache.activePool,
            contractsCache.usmToken,
            gasPoolAddress,
            LibMojoDiamond.USM_GAS_COMPENSATION,
            LibMojoDiamond.USM_GAS_COMPENSATION
        );

        emit TroveUpdated(
            _troveOwner,
            vars.compositeDebt,
            _colls,
            _amounts,
            LibMojoDiamond.BorrowerOperation.openTrove
        );
        emit USMBorrowingFeePaid(_troveOwner, vars.USMFee);
    }

    // add collateral to trove. Calls _adjustTrove with correct params.
    function addColl(
        address[] calldata _collsIn,
        uint256[] calldata _amountsIn,
        address _upperHint,
        address _lowerHint,
        uint256 _maxFeePercentage
    ) external override nonReentrant {
        LibMojoDiamond.AdjustTrove_Params memory params;
        params._collsIn = _collsIn;
        params._amountsIn = _amountsIn;
        params._upperHint = _upperHint;
        params._lowerHint = _lowerHint;
        params._maxFeePercentage = _maxFeePercentage;

        // check that all _collsIn collateral types are in the whitelist
        _requireValidDepositCollateral(_collsIn, params._amountsIn);
        _requireNoDuplicateColls(_collsIn); // Check that there is no overlap with in or out in itself

        // pull in deposit collateral
        _transferCollateralsIntoActivePool(
            msg.sender,
            params._collsIn,
            params._amountsIn
        );
        _adjustTrove(params);
    }

    // add collateral to trove. Calls _adjustTrove with correct params.
    function addCollLeverUp(
        address[] memory _collsIn,
        uint256[] memory _amountsIn,
        uint256[] memory _leverages,
        uint256[] memory _maxSlippages,
        uint256 _USMAmount,
        address _upperHint,
        address _lowerHint,
        uint256 _maxFeePercentage
    ) external override nonReentrant {
        LibMojoDiamond.AdjustTrove_Params memory params;
        params._upperHint = _upperHint;
        params._lowerHint = _lowerHint;
        params._maxFeePercentage = _maxFeePercentage;
        uint256 collsLen = _collsIn.length;

        // check that all _collsIn collateral types are in the whitelist
        _requireValidDepositCollateral(_collsIn, _amountsIn);
        // Must check that other passed in arrays are correct length
        _requireLengthsEqual(collsLen, _leverages.length);
        _requireLengthsEqual(collsLen, _maxSlippages.length);
        _requireNoDuplicateColls(params._collsIn); // Check that there is no overlap with in or out in itself

        uint additionalTokenAmount;
        uint additionalUSMDebt;
        uint totalUSMDebtFromLever;
        for (uint256 i; i < collsLen; ++i) {
            if (_leverages[i] != 0) {
                (additionalTokenAmount, additionalUSMDebt) = _singleLeverUp(
                    _collsIn[i],
                    _amountsIn[i],
                    _leverages[i],
                    _maxSlippages[i]
                );
                // Transfer into active pool, non levered amount.
                _singleTransferCollateralIntoActivePool(
                    msg.sender,
                    _collsIn[i],
                    _amountsIn[i]
                );
                // additional token amount was set to the original amount * leverage.
                _amountsIn[i] = additionalTokenAmount.add(_amountsIn[i]);
                totalUSMDebtFromLever = totalUSMDebtFromLever.add(
                    additionalUSMDebt
                );
            } else {
                // Otherwise skip and do normal transfer that amount into active pool.
                _singleTransferCollateralIntoActivePool(
                    msg.sender,
                    _collsIn[i],
                    _amountsIn[i]
                );
            }
        }
        _USMAmount = _USMAmount + totalUSMDebtFromLever;
        params._totalUSMDebtFromLever = totalUSMDebtFromLever;

        params._USMChange = _USMAmount;
        params._isDebtIncrease = true;

        params._collsIn = _collsIn;
        params._amountsIn = _amountsIn;
        _adjustTrove(params);
    }

    // Withdraw collateral from a trove. Calls _adjustTrove with correct params.
    function withdrawColl(
        address[] calldata _collsOut,
        uint256[] calldata _amountsOut,
        address _upperHint,
        address _lowerHint
    ) external override nonReentrant {
        LibMojoDiamond.AdjustTrove_Params memory params;
        params._collsOut = _collsOut;
        params._amountsOut = _amountsOut;
        params._upperHint = _upperHint;
        params._lowerHint = _lowerHint;

        // check that all _collsOut collateral types are in the whitelist
        _requireValidDepositCollateral(params._collsOut, params._amountsOut);
        _requireNoDuplicateColls(params._collsOut); // Check that there is no overlap with in or out in itself

        _adjustTrove(params);
    }

    // Withdraw USM tokens from a trove: mint new USM tokens to the owner, and increase the trove's debt accordingly.
    // Calls _adjustTrove with correct params.
    function withdrawUSM(
        uint256 _maxFeePercentage,
        uint256 _USMAmount,
        address _upperHint,
        address _lowerHint
    ) external override nonReentrant {
        LibMojoDiamond.AdjustTrove_Params memory params;
        params._USMChange = _USMAmount;
        params._maxFeePercentage = _maxFeePercentage;
        params._upperHint = _upperHint;
        params._lowerHint = _lowerHint;
        params._isDebtIncrease = true;
        _adjustTrove(params);
    }

    // Repay USM tokens to a Trove: Burn the repaid USM tokens, and reduce the trove's debt accordingly.
    // Calls _adjustTrove with correct params.
    function repayUSM(
        uint256 _USMAmount,
        address _upperHint,
        address _lowerHint
    ) external override nonReentrant {
        LibMojoDiamond.AdjustTrove_Params memory params;
        params._USMChange = _USMAmount;
        params._upperHint = _upperHint;
        params._lowerHint = _lowerHint;
        params._isDebtIncrease = false;
        _adjustTrove(params);
    }

    // Adjusts trove with multiple colls in / out. Calls _adjustTrove with correct params.
    function adjustTrove(
        address[] calldata _collsIn,
        uint256[] memory _amountsIn,
        address[] calldata _collsOut,
        uint256[] calldata _amountsOut,
        uint256 _USMChange,
        bool _isDebtIncrease,
        address _upperHint,
        address _lowerHint,
        uint256 _maxFeePercentage
    ) external override nonReentrant {
        // check that all _collsIn collateral types are in the whitelist
        _requireValidDepositCollateral(_collsIn, _amountsIn);
        _requireValidDepositCollateral(_collsOut, _amountsOut);
        _requireNoOverlapColls(_collsIn, _collsOut); // check that there are no overlap between _collsIn and _collsOut
        _requireNoDuplicateColls(_collsIn);
        _requireNoDuplicateColls(_collsOut);

        // pull in deposit collateral
        _transferCollateralsIntoActivePool(msg.sender, _collsIn, _amountsIn);
        uint256[] memory maxSlippages = new uint256[](0);

        LibMojoDiamond.AdjustTrove_Params memory params = LibMojoDiamond
            .AdjustTrove_Params(
                _collsIn,
                _amountsIn,
                _collsOut,
                _amountsOut,
                maxSlippages,
                _USMChange,
                0,
                _isDebtIncrease,
                false,
                _upperHint,
                _lowerHint,
                _maxFeePercentage
            );

        _adjustTrove(params);
    }

    /*
     * _adjustTrove(): Alongside a debt change, this function can perform either a collateral top-up or a collateral withdrawal.
     * the ith element of _amountsIn and _amountsOut corresponds to the ith element of the addresses _collsIn and _collsOut passed in
     *
     * Should be called after the collsIn has been sent to ActivePool
     */
    function _adjustTrove(LibMojoDiamond.AdjustTrove_Params memory params)
        internal
    {
        LibMojoDiamond.DiamondStorage storage ds = LibMojoDiamond
            .diamondStorage();
        LibMojoDiamond.ContractsCache memory contractsCache = LibMojoDiamond
            .ContractsCache(ds.troveManager, ds.activePool, ds.usmToken);
        LibMojoDiamond.LocalVariables_adjustTrove memory vars;

        // bool isRecoveryMode = _checkRecoveryMode();

        if (params._isDebtIncrease) {
            _requireValidMaxFeePercentage(
                params._maxFeePercentage /* ,
                isRecoveryMode */
            );
            _requireNonZeroDebtChange(params._USMChange);
        }

        // Checks that at least one array is non-empty, and also that at least one value is 1.
        _requireNonZeroAdjustment(
            params._amountsIn,
            params._amountsOut,
            params._USMChange
        );
        _requireTroveisActive(contractsCache.troveManager, msg.sender);

        contractsCache.troveManager.applyPendingRewards(msg.sender);
        vars.netDebtChange = params._USMChange;

        vars.VCin = _getVC(params._collsIn, params._amountsIn);
        vars.VCout = _getVC(params._collsOut, params._amountsOut);

        if (params._isDebtIncrease) {
            vars.maxFeePercentageFactor = LiquityMath._max(
                vars.VCin,
                params._USMChange
            );
        } else {
            vars.maxFeePercentageFactor = vars.VCin;
        }

        // If the adjustment incorporates a debt increase and system is in Normal Mode (recovery mode disabled in Mojo), then trigger a borrowing fee
        if (
            params._isDebtIncrease /*  && !isRecoveryMode */
        ) {
            vars.USMFee = _triggerBorrowingFee(
                contractsCache.troveManager,
                contractsCache.usmToken,
                params._USMChange,
                vars.maxFeePercentageFactor, // max of VC in and USM change here to see what the max borrowing fee is triggered on.
                params._maxFeePercentage
            );
            // passed in max fee minus actual fee percent applied so far
            params._maxFeePercentage = params._maxFeePercentage.sub(
                vars.USMFee.mul(LibMojoDiamond.DECIMAL_PRECISION).div(
                    vars.maxFeePercentageFactor
                )
            );
            vars.netDebtChange = vars.netDebtChange + vars.USMFee; // The raw debt change includes the fee
        }

        // get current portfolio in trove
        (vars.currAssets, vars.currAmounts) = contractsCache
            .troveManager
            .getTroveColls(msg.sender);
        // current VC based on current portfolio and latest prices
        vars.currVC = _getVC(vars.currAssets, vars.currAmounts);

        // get new portfolio in trove after changes. Will error if invalid changes:
        (vars.newAssets, vars.newAmounts) = _getNewPortfolio(
            vars.currAssets,
            vars.currAmounts,
            params._collsIn,
            params._amountsIn,
            params._collsOut,
            params._amountsOut
        );
        // new VC based on new portfolio and latest prices
        vars.newVC = _getVC(vars.newAssets, vars.newAmounts);

        vars.isCollIncrease = vars.newVC > vars.currVC;
        vars.collChange = 0;
        if (vars.isCollIncrease) {
            vars.collChange = (vars.newVC - vars.currVC);
        } else {
            vars.collChange = (vars.currVC - vars.newVC);
        }

        vars.debt = contractsCache.troveManager.getTroveDebt(msg.sender);

        if (params._collsIn.length != 0) {
            vars.variableUSMFee = _getTotalVariableDepositFee(
                params._collsIn,
                params._amountsIn,
                vars.VCin,
                vars.VCout,
                vars.maxFeePercentageFactor,
                params._maxFeePercentage,
                contractsCache
            );
        }

        // Get the trove's old ICR before the adjustment, and what its new ICR will be after the adjustment
        vars.oldICR = LiquityMath._computeCR(vars.currVC, vars.debt);

        vars.debt += vars.variableUSMFee;

        vars.newICR = _getNewICRFromTroveChange(
            vars.newVC,
            vars.debt, // with variableUSMFee already added.
            vars.netDebtChange,
            params._isDebtIncrease
        );

        // Check the adjustment satisfies all conditions for the current system mode
        _requireValidAdjustmentInCurrentMode(
            // isRecoveryMode,
            params._amountsOut,
            params._isDebtIncrease,
            vars
        );

        // When the adjustment is a debt repayment, check it's a valid amount and that the caller has enough USM
        if (
            !params._isUnlever &&
            !params._isDebtIncrease &&
            params._USMChange != 0
        ) {
            _requireAtLeastMinNetDebt(
                _getNetDebt(vars.debt) - vars.netDebtChange
            );
            _requireValidUSMRepayment(vars.debt, vars.netDebtChange);
            _requireSufficientUSMBalance(
                contractsCache.usmToken,
                msg.sender,
                vars.netDebtChange
            );
        }

        if (params._collsIn.length != 0) {
            contractsCache.activePool.receiveCollateral(
                params._collsIn,
                params._amountsIn
            );
        }

        (vars.newVC, vars.newDebt) = _updateTroveFromAdjustment(
            contractsCache.troveManager,
            msg.sender,
            vars.newAssets,
            vars.newAmounts,
            vars.newVC,
            vars.netDebtChange,
            params._isDebtIncrease,
            vars.variableUSMFee
        );

        contractsCache.troveManager.updateStakeAndTotalStakes(msg.sender);

        // Re-insert trove in to the sorted list
        ds.sortedTroves.reInsert(
            msg.sender,
            vars.newICR,
            params._upperHint,
            params._lowerHint
        );

        emit TroveUpdated(
            msg.sender,
            vars.newDebt,
            vars.newAssets,
            vars.newAmounts,
            LibMojoDiamond.BorrowerOperation.adjustTrove
        );
        emit USMBorrowingFeePaid(msg.sender, vars.USMFee);

        // in case of unlever up
        if (params._isUnlever) {
            // 1. Withdraw the collateral from active pool and perform swap using single unlever up and corresponding router.
            _unleverColls(
                contractsCache.activePool,
                params._collsOut,
                params._amountsOut,
                params._maxSlippages
            );

            // 2. update the trove with the new collateral and debt, repaying the total amount of USM specified.
            // if not enough coll sold for USM, must cover from user balance
            _requireAtLeastMinNetDebt(
                _getNetDebt(vars.debt).sub(params._USMChange)
            );
            _requireValidUSMRepayment(vars.debt, params._USMChange);
            _requireSufficientUSMBalance(
                contractsCache.usmToken,
                msg.sender,
                params._USMChange
            );
            _repayUSM(
                contractsCache.activePool,
                contractsCache.usmToken,
                msg.sender,
                params._USMChange
            );
        } else {
            // Use the unmodified _USMChange here, as we don't send the fee to the user
            _moveUSM(
                contractsCache.activePool,
                contractsCache.usmToken,
                msg.sender,
                params._USMChange - params._totalUSMDebtFromLever, // 0 in non lever case
                params._isDebtIncrease,
                vars.netDebtChange
            );

            // Additionally move the variable deposit fee to the active pool manually, as it is always an increase in debt
            _withdrawUSM(
                contractsCache.activePool,
                contractsCache.usmToken,
                msg.sender,
                0,
                vars.variableUSMFee
            );

            // transfer withdrawn collateral to msg.sender from ActivePool
            ds.activePool.sendCollateralsUnwrap(
                msg.sender,
                msg.sender,
                params._collsOut,
                params._amountsOut
            );
        }
    }

    // internal function for minting USM at certain leverage and max slippage, and then performing
    // swap with whitelist's approved router.
    function _singleUnleverUp(
        address _token,
        uint256 _amount,
        uint256 _maxSlippage
    ) internal returns (uint256 _finalUSMAmount) {
        require(_maxSlippage <= 1e18, "WrongSlippage");

        LibMojoDiamond.DiamondStorage storage ds = LibMojoDiamond
            .diamondStorage();

        // if wrapped token, then does it automatically transfer to active pool?
        // It should actually transfer to the owner, who will have bOps pre approved
        // cause of original approve
        // TODO: modify router
        IYetiRouter router = IYetiRouter(
            ds.whitelist.getDefaultRouterAddress(_token)
        );
        // then calculate value amount of expected USM output based on amount of token to sell

        uint valueOfCollateral = ds.whitelist.getValueUSD(_token, _amount);
        uint256 slippageAdjustedValue = (valueOfCollateral *
            (LibMojoDiamond.DECIMAL_PRECISION - _maxSlippage)) / 1e18;
        IERC20 usmTokenCached = ds.usmToken;
        require(IERC20(_token).approve(address(router), valueOfCollateral));
        uint256 balanceBefore = ds.usmToken.balanceOf(address(this));
        _finalUSMAmount = router.unRoute(
            address(this),
            _token,
            address(usmTokenCached),
            _amount,
            slippageAdjustedValue
        );
        require(
            usmTokenCached.balanceOf(address(this)) ==
                (balanceBefore + _finalUSMAmount),
            "BO:USMNotSentUnLever"
        );
    }

    // Takes the colls and amounts, transfer non levered from the active pool to the user, and unlevered to this contract
    // temporarily. Then takes the unlevered ones and calls relevant router to swap them to the user.
    function _unleverColls(
        IActivePool _activePool,
        address[] memory _colls,
        uint256[] memory _amounts,
        uint256[] memory _maxSlippages
    ) internal {
        uint256 collsLen = _colls.length;
        for (uint256 i; i < collsLen; ++i) {
            if (_maxSlippages[i] != 0) {
                _activePool.sendSingleCollateral(
                    address(this),
                    _colls[i],
                    _amounts[i]
                );
                _singleUnleverUp(_colls[i], _amounts[i], _maxSlippages[i]);
            } else {
                _activePool.sendSingleCollateralUnwrap(
                    msg.sender,
                    msg.sender,
                    _colls[i],
                    _amounts[i]
                );
            }
        }
    }

    // Withdraw collateral from a trove. Calls _adjustTrove with correct params.
    // Specifies amount of collateral to withdraw and how much debt to repay,
    // Can withdraw coll and *only* pay back debt using this function. Will take
    // the collateral given and send USM back to user. Then they will pay back debt
    // first transfers amount of collateral from active pool then sells.
    // calls _singleUnleverUp() to perform the swaps using the wrappers.
    // should have no fees.
    function withdrawCollUnleverUp(
        address[] calldata _collsOut,
        uint256[] calldata _amountsOut,
        uint256[] calldata _maxSlippages,
        uint256 _USMAmount,
        address _upperHint,
        address _lowerHint
    ) external override nonReentrant {
        // check that all _collsOut collateral types are in the whitelist
        _requireValidDepositCollateral(_collsOut, _amountsOut);
        _requireNoDuplicateColls(_collsOut); // Check that there is no overlap with out in itself
        _requireLengthsEqual(_amountsOut.length, _maxSlippages.length);

        LibMojoDiamond.AdjustTrove_Params memory params;
        params._collsOut = _collsOut;
        params._amountsOut = _amountsOut;
        params._maxSlippages = _maxSlippages;
        params._USMChange = _USMAmount;
        params._upperHint = _upperHint;
        params._lowerHint = _lowerHint;
        params._isUnlever = true;

        _adjustTrove(params);
    }

    function closeTroveUnlever(
        address[] calldata _collsOut,
        uint256[] calldata _amountsOut,
        uint256[] calldata _maxSlippages
    ) external override nonReentrant {
        LibMojoDiamond.CloseTrove_Params memory params = LibMojoDiamond
            .CloseTrove_Params({
                _collsOut: _collsOut,
                _amountsOut: _amountsOut,
                _maxSlippages: _maxSlippages,
                _isUnlever: true
            });
        _closeTrove(params);
    }

    function closeTrove() external override nonReentrant {
        LibMojoDiamond.CloseTrove_Params memory params; // default false
        _closeTrove(params);
    }

    /**
     * Closes trove by applying pending rewards, making sure that the USM Balance is sufficient, and transferring the
     * collateral to the owner, and repaying the debt.
     * if it is a unlever, then it will transfer the collaterals / sell before. Otherwise it will just do it last.
     */
    function _closeTrove(LibMojoDiamond.CloseTrove_Params memory params)
        internal
    {
        LibMojoDiamond.DiamondStorage storage ds = LibMojoDiamond
            .diamondStorage();
        LibMojoDiamond.ContractsCache memory contractsCache = LibMojoDiamond
            .ContractsCache(ds.troveManager, ds.activePool, ds.usmToken);

        _requireTroveisActive(contractsCache.troveManager, msg.sender);
        // _requireNotInRecoveryMode();         // recovery mode is disabled, so always in normal mode or not

        contractsCache.troveManager.applyPendingRewards(msg.sender);

        uint256 troveVC = contractsCache.troveManager.getTroveVC(msg.sender); // should get the latest VC
        (address[] memory colls, uint256[] memory amounts) = contractsCache
            .troveManager
            .getTroveColls(msg.sender);
        uint256 debt = contractsCache.troveManager.getTroveDebt(msg.sender);

        // if unlever, will do extra.
        uint finalUSMAmount;
        uint USMAmount;
        if (params._isUnlever) {
            // Withdraw the collateral from active pool and perform swap using single unlever up and corresponding router.
            _unleverColls(
                contractsCache.activePool,
                colls,
                amounts,
                params._maxSlippages
            );
            // tracks the amount of USM that is received from swaps. Will send the _USMAmount back to repay debt while keeping remainder.
        }

        // do check after unlever (if applies)
        _requireSufficientUSMBalance(
            contractsCache.usmToken,
            msg.sender,
            debt.sub(USM_GAS_COMPENSATION)
        );
        uint256 newTCR = _getNewTCRFromTroveChange(troveVC, false, debt, false);
        _requireNewTCRisAboveCCR(newTCR);

        contractsCache.troveManager.removeStake(msg.sender);
        contractsCache.troveManager.closeTrove(msg.sender);

        address[] memory finalColls;
        uint256[] memory finalAmounts;

        emit TroveUpdated(
            msg.sender,
            0,
            finalColls,
            finalAmounts,
            BorrowerOperation.closeTrove
        );

        // Burn the repaid USM from the user's balance and the gas compensation from the Gas Pool
        _repayUSM(
            contractsCache.activePool,
            contractsCache.usmToken,
            msg.sender,
            debt.sub(USM_GAS_COMPENSATION)
        );
        _repayUSM(
            contractsCache.activePool,
            contractsCache.usmToken,
            gasPoolAddress,
            USM_GAS_COMPENSATION
        );

        // Send the collateral back to the user
        // Also sends the rewards
        if (!params._isUnlever) {
            contractsCache.activePool.sendCollateralsUnwrap(
                msg.sender,
                msg.sender,
                colls,
                amounts
            );
        }
    }

    /**
     * Claim remaining collateral from a redemption or from a liquidation with ICR > MCR in Recovery Mode
     * to do all necessary interactions. Can delete if this is the only way to reduce size.
     */
    function claimCollateral() external override {
        LibMojoDiamond.DiamondStorage storage ds = LibMojoDiamond
            .diamondStorage();
        // send collateral from CollSurplus Pool to owner
        ds.collSurplusPool.claimColl(msg.sender);
    }

    // --- Helper functions ---

    /**
     * Gets the variable deposit fee from the whitelist calculation. Multiplies the
     * fee by the vc of the collateral.
     */
    function _getTotalVariableDepositFee(
        address[] memory _tokensIn,
        uint256[] memory _amountsIn,
        uint256 _VCin,
        uint256 _VCout,
        uint256 _maxFeePercentageFactor,
        uint256 _maxFeePercentage,
        ContractsCache memory _contractsCache
    ) internal returns (uint256 USMFee) {
        if (_VCin == 0) {
            return 0;
        }
        LibMojoDiamond.DiamondStorage storage ds = LibMojoDiamond
            .diamondStorage();
        LibMojoDiamond.DepositFeeCalc memory vars;
        // active pool total VC at current state.
        vars.systemTotalVC =
            _contractsCache.activePool.getVC() +
            defaultPool.getVC();
        // active pool total VC post adding and removing all collaterals
        uint256 activePoolVCPost = vars.systemTotalVC + _VCin - _VCout;
        uint256 whitelistFee;
        uint256 tokensLen = _tokensIn.length;
        for (uint256 i; i < tokensLen; ++i) {
            vars.token = _tokensIn[i];
            // VC value of collateral of this type inputted
            vars.collateralInputVC = ds.whitelist.getValueVC(
                vars.token,
                _amountsIn[i]
            );

            // total value in VC of this collateral in active pool (post adding input)
            vars.systemCollateralVC =
                _contractsCache.activePool.getCollateralVC(vars.token) +
                defaultPool.getCollateralVC(vars.token);

            // (collateral VC In) * (Collateral's Fee Given Yeti Protocol Backed by Given Collateral)
            whitelistFee = ds.whitelist.getFeeAndUpdate(
                vars.token,
                vars.collateralInputVC,
                vars.systemCollateralVC,
                vars.systemTotalVC,
                activePoolVCPost
            );
            if (_isBeforeFeeBootstrapPeriod()) {
                whitelistFee = LiquityMath._min(whitelistFee, 1e16); // cap at 1%
            }
            vars.collateralUSMFee =
                (vars.collateralInputVC * whitelistFee) /
                1e18;

            USMFee = USMFee.add(vars.collateralUSMFee);
        }
        _requireUserAcceptsFee(
            USMFee,
            _maxFeePercentageFactor,
            _maxFeePercentage
        );
        _triggerDepositFee(_contractsCache.usmToken, USMFee);
    }

    // Transfer in collateral and send to ActivePool
    // (where collateral is held)
    function _transferCollateralsIntoActivePool(
        address _from,
        address[] memory _colls,
        uint256[] memory _amounts
    ) internal {
        uint256 amountsLen = _amounts.length;
        for (uint256 i; i < amountsLen; ++i) {
            address collAddress = _colls[i];
            uint256 amount = _amounts[i];
            _singleTransferCollateralIntoActivePool(_from, collAddress, amount);
        }
    }

    // does one transfer of collateral into active pool. Checks that it transferred to the active pool correctly.
    function _singleTransferCollateralIntoActivePool(
        address _from,
        address _coll,
        uint256 _amount
    ) internal {
        if (whitelist.isWrapped(_coll)) {
            // If wrapped asset then it wraps it and sends the wrapped version to the active pool,
            // and updates reward balance to the new owner.
            IWAsset(_coll).wrap(_amount, _from, address(activePool), _from);
        } else {
            require(
                IERC20(_coll).transferFrom(_from, address(activePool), _amount),
                "BO:TransferCollsFailed"
            );
        }
    }

    /**
     * Triggers normal borrowing fee, calculated from base rate and on USM amount.
     */
    function _triggerBorrowingFee(
        ITroveManager _troveManager,
        IUSMToken _usmToken,
        uint256 _USMAmount,
        uint256 _maxFeePercentageFactor,
        uint256 _maxFeePercentage
    ) internal returns (uint256) {
        _troveManager.decayBaseRateFromBorrowing(); // decay the baseRate state variable
        uint256 USMFee = _troveManager.getBorrowingFee(_USMAmount);

        _requireUserAcceptsFee(
            USMFee,
            _maxFeePercentageFactor,
            _maxFeePercentage
        );

        // Send fee to sMOJO contract
        _usmToken.mint(sMOJOAddress, USMFee);
        return USMFee;
    }

    function _triggerDepositFee(IUSMToken _usmToken, uint256 _USMFee) internal {
        // Send fee to sMOJO contract
        _usmToken.mint(sMOJOAddress, _USMFee);
    }

    // Update trove's coll and debt based on whether they increase or decrease
    function _updateTroveFromAdjustment(
        ITroveManager _troveManager,
        address _borrower,
        address[] memory _finalColls,
        uint256[] memory _finalAmounts,
        uint256 _newVC,
        uint256 _debtChange,
        bool _isDebtIncrease,
        uint256 _variableUSMFee
    ) internal returns (uint256, uint256) {
        uint256 newDebt;
        _troveManager.updateTroveColl(_borrower, _finalColls, _finalAmounts);
        if (_isDebtIncrease) {
            // if debt increase, increase by both amounts
            newDebt = _troveManager.increaseTroveDebt(
                _borrower,
                _debtChange.add(_variableUSMFee)
            );
        } else {
            if (_debtChange > _variableUSMFee) {
                // if debt decrease, and greater than variable fee, decrease
                newDebt = _troveManager.decreaseTroveDebt(
                    _borrower,
                    _debtChange - _variableUSMFee
                ); // already checked no safemath needed
            } else {
                // otherwise increase by opposite subtraction
                newDebt = _troveManager.increaseTroveDebt(
                    _borrower,
                    _variableUSMFee - _debtChange
                ); // already checked no safemath needed
            }
        }

        return (_newVC, newDebt);
    }

    // gets the finalColls and finalAmounts after all deposits and withdrawals have been made
    // this function will error if trying to deposit a collateral that is not in the whitelist
    // or trying to withdraw more collateral of any type that is not in the trove
    function _getNewPortfolio(
        address[] memory _initialTokens,
        uint256[] memory _initialAmounts,
        address[] memory _tokensIn,
        uint256[] memory _amountsIn,
        address[] memory _tokensOut,
        uint256[] memory _amountsOut
    ) internal view returns (address[] memory, uint256[] memory) {
        _requireValidDepositCollateral(_tokensIn, _amountsIn);
        _requireValidDepositCollateral(_tokensOut, _amountsOut);

        // Initial Colls + Input Colls
        newColls memory cumulativeIn = MojoCustomBase._sumColls(
            _initialTokens,
            _initialAmounts,
            _tokensIn,
            _amountsIn
        );

        newColls memory newPortfolio = MojoCustomBase._subColls(
            cumulativeIn,
            _tokensOut,
            _amountsOut
        );
        return (newPortfolio.tokens, newPortfolio.amounts);
    }

    // Moves the USM around based on whether it is an increase or decrease in debt.
    function _moveUSM(
        IActivePool _activePool,
        IUSMToken _usmToken,
        address _borrower,
        uint256 _USMChange,
        bool _isDebtIncrease,
        uint256 _netDebtChange
    ) internal {
        if (_isDebtIncrease) {
            _withdrawUSM(
                _activePool,
                _usmToken,
                _borrower,
                _USMChange,
                _netDebtChange
            );
        } else {
            _repayUSM(_activePool, _usmToken, _borrower, _USMChange);
        }
    }

    // Issue the specified amount of USM to _account and increases the total active debt (_netDebtIncrease potentially includes a USMFee)
    function _withdrawUSM(
        IActivePool _activePool,
        IUSMToken _usmToken,
        address _account,
        uint256 _USMAmount,
        uint256 _netDebtIncrease
    ) internal {
        _activePool.increaseUSMDebt(_netDebtIncrease);
        _usmToken.mint(_account, _USMAmount);
    }

    // Burn the specified amount of USM from _account and decreases the total active debt
    function _repayUSM(
        IActivePool _activePool,
        IUSMToken _usmToken,
        address _account,
        uint256 _USM
    ) internal {
        _activePool.decreaseUSMDebt(_USM);
        _usmToken.burn(_account, _USM);
    }

    // --- 'Require' wrapper functions ---

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
        return block.timestamp < ds.deploymentTime + ds.BOOTSTRAP_PERIOD; // won't overflow
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

    function _requireValidAdjustmentInCurrentMode(
        // bool _isRecoveryMode,
        uint256[] memory _collWithdrawal,
        bool _isDebtIncrease,
        LocalVariables_adjustTrove memory _vars
    ) internal view {
        /*
         *In Recovery Mode, only allow:
         *
         * - Pure collateral top-up
         * - Pure debt repayment
         * - Collateral top-up with debt repayment
         * - A debt increase combined with a collateral top-up which makes the ICR >= 150% and improves the ICR (and by extension improves the TCR).
         *
         * In Normal Mode, ensure:
         *
         * - The new ICR is above MCR
         * - The adjustment won't pull the TCR below CCR
         */
        // if (_isRecoveryMode) {
        //     _requireNoCollWithdrawal(_collWithdrawal);
        //     if (_isDebtIncrease) {
        //         _requireICRisAboveCCR(_vars.newICR);
        //         _requireNewICRisAboveOldICR(_vars.newICR, _vars.oldICR);
        //     }
        // } else {
        //     // if Normal Mode
        //     _requireICRisAboveMCR(_vars.newICR);
        //     _vars.newTCR = _getNewTCRFromTroveChange(
        //         _vars.collChange,
        //         _vars.isCollIncrease,
        //         _vars.netDebtChange,
        //         _isDebtIncrease
        //     );
        //     _requireNewTCRisAboveCCR(_vars.newTCR);
        // }

        // if Normal Mode
        _requireICRisAboveMCR(_vars.newICR);
        _vars.newTCR = _getNewTCRFromTroveChange(
            _vars.collChange,
            _vars.isCollIncrease,
            _vars.netDebtChange,
            _isDebtIncrease
        );
        _requireNewTCRisAboveCCR(_vars.newTCR);
    }

    function _requireICRisAboveMCR(uint256 _newICR) internal pure {
        require(
            _newICR >= LibMojoDiamond.diamondStorage().MCR,
            "BO:ReqICR>MCR"
        );
    }

    function _requireICRisAboveCCR(uint256 _newICR) internal pure {
        require(
            _newICR >= LibMojoDiamond.diamondStorage().CCR,
            "BO:ReqICR>CCR"
        );
    }

    function _requireNewICRisAboveOldICR(uint256 _newICR, uint256 _oldICR)
        internal
        pure
    {
        require(_newICR >= _oldICR, "BO:RecMode:ICR<oldICR");
    }

    function _requireNewTCRisAboveCCR(uint256 _newTCR) internal pure {
        require(
            _newTCR >= LibMojoDiamond.diamondStorage().CCR,
            "BO:ReqTCR>CCR"
        );
    }

    function _requireAtLeastMinNetDebt(uint256 _netDebt) internal pure {
        require(
            _netDebt >= LibMojoDiamond.diamondStorage().MIN_NET_DEBT,
            "BO:netDebt<2000"
        );
    }

    function _requireValidUSMRepayment(
        uint256 _currentDebt,
        uint256 _debtRepayment
    ) internal pure {
        require(
            _debtRepayment <=
                (_currentDebt -
                    LibMojoDiamond.diamondStorage().USM_GAS_COMPENSATION),
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
        LibMojoDiamond.DiamondStorage storage ds = LibMojoDiamond
            .diamondStorage();
        if (
            _maxFeePercentage > ds.DECIMAL_PRECISION ||
            _maxFeePercentage < ds.BORROWING_FEE_FLOOR
        ) {
            revert("BO:InvalidMaxFee");
        }
    }

    // checks lengths are all good and that all passed in routers are valid routers
    // function _requireValidRouterParams(
    //     address[] memory _finalRoutedColls,
    //     uint[] memory _amounts,
    //     uint[] memory _minSwapAmounts,
    //     IYetiRouter[] memory _routers) internal view {
    //     require(_finalRoutedColls.length == _amounts.length,  "_requireValidRouterParams: _finalRoutedColls length mismatch");
    //     require(_amounts.length == _routers.length, "_requireValidRouterParams: _routers length mismatch");
    //     require(_amounts.length == _minSwapAmounts.length, "_minSwapAmounts: finalRoutedColls length mismatch");
    //     for (uint256 i; i < _routers.length; ++i) {
    //         require(whitelist.isValidRouter(address(_routers[i])), "_requireValidRouterParams: not a valid router");
    //     }
    // }

    // // requires that avax indices are in order
    // function _requireRouterAVAXIndicesInOrder(uint[] memory _indices) internal pure {
    //     for (uint256 i; i < _indices.length - 1; ++i) {
    //         require(_indices[i] < _indices[i.add(1)], "_requireRouterAVAXIndicesInOrder: indices out of order");
    //     }
    // }

    // --- ICR and TCR getters ---

    // Compute the new collateral ratio, considering the change in coll and debt. Assumes 0 pending rewards.
    function _getNewICRFromTroveChange(
        uint256 _newVC,
        uint256 _debt,
        uint256 _debtChange,
        bool _isDebtIncrease
    ) internal pure returns (uint256) {
        uint256 newDebt = _isDebtIncrease
            ? (_debt + _debtChange)
            : (_debt - _debtChange);

        uint256 newICR = LiquityMath._computeCR(_newVC, newDebt);
        return newICR;
    }

    function _getNewTCRFromTroveChange(
        uint256 _collChange,
        bool _isCollIncrease,
        uint256 _debtChange,
        bool _isDebtIncrease
    ) internal view returns (uint256) {
        uint256 totalColl = getEntireSystemColl();
        uint256 totalDebt = getEntireSystemDebt();

        totalColl = _isCollIncrease
            ? (totalColl + _collChange)
            : (totalColl - _collChange);
        totalDebt = _isDebtIncrease
            ? (totalDebt + _debtChange)
            : (totalDebt - _debtChange);

        uint256 newTCR = LiquityMath._computeCR(totalColl, totalDebt);
        return newTCR;
    }

    function getCompositeDebt(uint256 _debt)
        external
        pure
        override
        returns (uint256)
    {
        return _getCompositeDebt(_debt);
    }

    //======================================================
    // Utils
    //======================================================
    function getName() external pure returns (string memory) {
        return "BorrowerOperations";
    }
}
