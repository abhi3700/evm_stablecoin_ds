// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "../interfaces/IBaseOracle.sol";
import "../interfaces/IWhitelist.sol";
import "../interfaces/IPriceFeed.sol";
import "../interfaces/IPriceCurve.sol";
import "../interfaces/IActivePool.sol";
import "../interfaces/IDefaultPool.sol";
// import "../interfaces/IStabilityPool.sol";
import "../interfaces/ICollSurplusPool.sol";
import "../interfaces/IERC20.sol";
import "../libs/math/LiquityMath.sol";
import "../dependencies/CheckContract.sol";
import "../libs/LibMojoDiamond.sol";

/**
 * Whitelist is the contract that keeps track of all the assets that the system takes as collateral.
 * It has `checkContractOwner()` function (in LibMojoDiamond.sol) to add or deprecate collaterals from the whitelist, change the price
 * curve, price feed, safety ratio, etc.
 */

contract Whitelist is IWhitelist, IBaseOracle, CheckContract {
    /**
     * ****************************************
     *
     * Errors
     * ****************************************
     WE0: collateral does not exist
     WE1: ratio must be less than 1.10
     WE2: collateral already exists
     WE3: collateral already deprecated
     WE4: collateral is already active
     WE5: New SR must be greater than previous SR
     WE6: caller must be BO
    */

    // using SafeMath for uint256;

    // struct CollateralParams {
    //     // Safety ratio
    //     uint256 ratio; // 10**18 * the ratio. i.e. ratio = .95 * 10**18 for 95%. More risky collateral has a lower ratio
    //     address oracle;
    //     uint256 decimals;
    //     address priceCurve;
    //     uint256 index;
    //     bool active;
    //     bool isWrapped;
    //     address defaultRouter;
    // }

    // IActivePool activePool;
    // IDefaultPool defaultPool;
    // // IStabilityPool stabilityPool;
    // ICollSurplusPool collSurplusPool;
    // address borrowerOperationsAddress;
    // bool private addressesSet;

    // mapping(address => CollateralParams) public collateralParams;

    // mapping(address => bool) public validRouter;

    // // list of all collateral types in collateralParams (active and deprecated)
    // // Addresses for easy access
    // address[] public validCollateral; // index maps to token address.

    event CollateralAdded(address _collateral);
    event CollateralDeprecated(address _collateral);
    event CollateralUndeprecated(address _collateral);
    event CollateralRemoved(address _collateral);
    event OracleChanged(address _collateral);
    event PriceCurveChanged(address _collateral);
    event RatioChanged(address _collateral);

    // Require that the collateral exists in the whitelist. If it is not the 0th index, and the
    // index is still 0 then it does not exist in the mapping.
    // no require here for valid collateral 0 index because that means it exists.
    modifier exists(address _collateral) {
        _exists(_collateral);
        _;
    }

    // Calling from here makes it not inline, reducing contract size and gas.
    function _exists(address _collateral) private view {
        LibMojoDiamond.DiamondStorage storage ds = LibMojoDiamond
            .diamondStorage();

        if (ds.validCollateral[0] != _collateral) {
            require(ds.collateralParams[_collateral].index != 0, "WE0");
        }
    }

    // ----------Only Owner Setter Functions----------

    // DONE: shift to Diamond library so as to use inside Diamond Proxy contract's constructor
    // function setAddresses(
    //     address _activePoolAddress,
    //     address _defaultPoolAddress,
    //     // address _stabilityPoolAddress,
    //     address _collSurplusPoolAddress,
    //     address _borrowerOperationsAddress
    // ) external override onlyOwner {
    //     LibMojoDiamond.DiamondStorage storage ds = LibMojoDiamond
    //         .diamondStorage();

    //     require(!ds.addressesSet, "addresses already set");
    //     checkContract(_activePoolAddress);
    //     checkContract(_defaultPoolAddress);
    //     // checkContract(_stabilityPoolAddress);
    //     checkContract(_collSurplusPoolAddress);
    //     checkContract(_borrowerOperationsAddress);

    //     ds.activePool = IActivePool(_activePoolAddress);
    //     ds.defaultPool = IDefaultPool(_defaultPoolAddress);
    //     // stabilityPool = IStabilityPool(_stabilityPoolAddress);
    //     ds.collSurplusPool = ICollSurplusPool(_collSurplusPoolAddress);
    //     ds.borrowerOperationsAddress = _borrowerOperationsAddress;
    //     ds.addressesSet = true;
    // }

    function addCollateral(
        address _collateral,
        uint256 _minRatio,
        address _oracle,
        uint256 _decimals,
        address _priceCurve,
        bool _isWrapped,
        address _routerAddress
    ) external {
        checkContract(_collateral);
        checkContract(_oracle);
        checkContract(_priceCurve);
        checkContract(_routerAddress);
        // If collateral list is not 0, and if the 0th index is not equal to this collateral,
        // then if index is 0 that means it is not set yet.
        require(_minRatio < 11e17, "WE1"); //=> greater than 1.1 would mean taking out more YUSD than collateral VC
        LibMojoDiamond.checkContractOwner();
        LibMojoDiamond.DiamondStorage storage ds = LibMojoDiamond
            .diamondStorage();

        if (ds.validCollateral.length != 0) {
            require(
                ds.validCollateral[0] != _collateral &&
                    ds.collateralParams[_collateral].index == 0,
                "WE2"
            );
        }

        ds.validCollateral.push(_collateral);
        ds.collateralParams[_collateral] = LibMojoDiamond.CollateralParams(
            _minRatio,
            _oracle,
            _decimals,
            _priceCurve,
            ds.validCollateral.length - 1,
            true,
            _isWrapped,
            _routerAddress
        );

        ds.activePool.addCollateralType(_collateral);
        ds.defaultPool.addCollateralTypeD(_collateral);
        // stabilityPool.addCollateralType(_collateral);
        ds.collSurplusPool.addCollateralType(_collateral);

        // throw event
        emit CollateralAdded(_collateral);
    }

    /**
     * Deprecate collateral by not allowing any more collateral to be added of this type.
     * Still can interact with it via validCollateral and CollateralParams
     */
    function deprecateCollateral(address _collateral)
        external
        exists(_collateral)
    {
        checkContract(_collateral);

        LibMojoDiamond.DiamondStorage storage ds = LibMojoDiamond
            .diamondStorage();
        LibMojoDiamond.checkContractOwner();

        require(ds.collateralParams[_collateral].active, "WE3");

        ds.collateralParams[_collateral].active = false;

        // throw event
        emit CollateralDeprecated(_collateral);
    }

    /**
     * Undeprecate collateral by allowing more collateral to be added of this type.
     * Still can interact with it via validCollateral and CollateralParams
     */
    function undeprecateCollateral(address _collateral)
        external
        exists(_collateral)
    {
        checkContract(_collateral);

        LibMojoDiamond.DiamondStorage storage ds = LibMojoDiamond
            .diamondStorage();
        LibMojoDiamond.checkContractOwner();

        require(!ds.collateralParams[_collateral].active, "WE4");

        ds.collateralParams[_collateral].active = true;

        // throw event
        emit CollateralUndeprecated(_collateral);
    }

    /**
     * Function to change oracles
     */
    function changeOracle(address _collateral, address _oracle)
        external
        exists(_collateral)
    {
        checkContract(_collateral);
        checkContract(_oracle);

        LibMojoDiamond.DiamondStorage storage ds = LibMojoDiamond
            .diamondStorage();
        LibMojoDiamond.checkContractOwner();

        ds.collateralParams[_collateral].oracle = _oracle;

        // throw event
        emit OracleChanged(_collateral);
    }

    /**
     * Function to change price curve
     */
    function changePriceCurve(address _collateral, address _priceCurve)
        external
        exists(_collateral)
    {
        checkContract(_collateral);
        checkContract(_priceCurve);
        uint256 lastFeePercent;
        uint256 lastFeeTime;

        LibMojoDiamond.DiamondStorage storage ds = LibMojoDiamond
            .diamondStorage();
        LibMojoDiamond.checkContractOwner();

        (lastFeePercent, lastFeeTime) = IPriceCurve(
            ds.collateralParams[_collateral].priceCurve
        ).getFeeCapAndTime();
        IPriceCurve(_priceCurve).setFeeCapAndTime(lastFeePercent, lastFeeTime);
        ds.collateralParams[_collateral].priceCurve = _priceCurve;

        // throw event
        emit PriceCurveChanged(_collateral);
    }

    /**
     * Function to change Safety ratio.
     */
    function changeRatio(address _collateral, uint256 _ratio)
        external
        exists(_collateral)
    {
        checkContract(_collateral);
        require(_ratio < 11e17, "WE1"); //=> greater than 1.1 would mean taking out more YUSD than collateral VC

        LibMojoDiamond.DiamondStorage storage ds = LibMojoDiamond
            .diamondStorage();
        LibMojoDiamond.checkContractOwner();
        require(ds.collateralParams[_collateral].ratio < _ratio, "WE5");
        ds.collateralParams[_collateral].ratio = _ratio;

        // throw event
        emit RatioChanged(_collateral);
    }

    // -----------Routers--------------

    function setDefaultRouter(address _collateral, address _router)
        external
        override
        exists(_collateral)
    {
        checkContract(_router);

        LibMojoDiamond.DiamondStorage storage ds = LibMojoDiamond
            .diamondStorage();
        LibMojoDiamond.checkContractOwner();
        ds.collateralParams[_collateral].defaultRouter = _router;
    }

    function getDefaultRouterAddress(address _collateral)
        external
        view
        override
        exists(_collateral)
        returns (address)
    {
        LibMojoDiamond.DiamondStorage storage ds = LibMojoDiamond
            .diamondStorage();
        return ds.collateralParams[_collateral].defaultRouter;
    }

    // ---------- View Functions -----------

    function isValidRouter(address _router)
        external
        view
        override
        returns (bool)
    {
        LibMojoDiamond.DiamondStorage storage ds = LibMojoDiamond
            .diamondStorage();
        return ds.validRouter[_router];
    }

    function getValidCollateral()
        external
        view
        override
        returns (address[] memory)
    {
        LibMojoDiamond.DiamondStorage storage ds = LibMojoDiamond
            .diamondStorage();
        return ds.validCollateral;
    }

    function getRatio(address _collateral)
        external
        view
        override
        exists(_collateral)
        returns (uint256)
    {
        LibMojoDiamond.DiamondStorage storage ds = LibMojoDiamond
            .diamondStorage();
        return ds.collateralParams[_collateral].ratio;
    }

    function getOracle(address _collateral)
        external
        view
        override
        exists(_collateral)
        returns (address)
    {
        LibMojoDiamond.DiamondStorage storage ds = LibMojoDiamond
            .diamondStorage();
        return ds.collateralParams[_collateral].oracle;
    }

    function getPriceCurve(address _collateral)
        external
        view
        override
        exists(_collateral)
        returns (address)
    {
        LibMojoDiamond.DiamondStorage storage ds = LibMojoDiamond
            .diamondStorage();
        return ds.collateralParams[_collateral].priceCurve;
    }

    function getIsActive(address _collateral)
        external
        view
        override
        exists(_collateral)
        returns (bool)
    {
        LibMojoDiamond.DiamondStorage storage ds = LibMojoDiamond
            .diamondStorage();
        return ds.collateralParams[_collateral].active;
    }

    function getDecimals(address _collateral)
        external
        view
        override
        exists(_collateral)
        returns (uint256)
    {
        LibMojoDiamond.DiamondStorage storage ds = LibMojoDiamond
            .diamondStorage();
        return ds.collateralParams[_collateral].decimals;
    }

    function getIndex(address _collateral)
        external
        view
        override
        exists(_collateral)
        returns (uint256)
    {
        LibMojoDiamond.DiamondStorage storage ds = LibMojoDiamond
            .diamondStorage();
        return (ds.collateralParams[_collateral].index);
    }

    function isWrapped(address _collateral)
        external
        view
        override
        returns (bool)
    {
        LibMojoDiamond.DiamondStorage storage ds = LibMojoDiamond
            .diamondStorage();
        return (ds.collateralParams[_collateral].isWrapped);
    }

    // Returned as fee percentage * 10**18. View function for external callers.
    function getFee(
        address _collateral,
        uint256 _collateralVCInput,
        uint256 _collateralVCBalancePost,
        uint256 _totalVCBalancePre,
        uint256 _totalVCBalancePost
    ) external view override exists(_collateral) returns (uint256 fee) {
        LibMojoDiamond.DiamondStorage storage ds = LibMojoDiamond
            .diamondStorage();
        IPriceCurve priceCurve = IPriceCurve(
            ds.collateralParams[_collateral].priceCurve
        );
        return
            priceCurve.getFee(
                _collateralVCInput,
                _collateralVCBalancePost,
                _totalVCBalancePre,
                _totalVCBalancePost
            );
    }

    // Returned as fee percentage * 10**18. Non view function for just borrower operations to call.
    function getFeeAndUpdate(
        address _collateral,
        uint256 _collateralVCInput,
        uint256 _collateralVCBalancePost,
        uint256 _totalVCBalancePre,
        uint256 _totalVCBalancePost
    ) external override exists(_collateral) returns (uint256 fee) {
        LibMojoDiamond.DiamondStorage storage ds = LibMojoDiamond
            .diamondStorage();
        require(
            msg.sender == ds.allAddresses2.borrowerOperationsAddress,
            "WE6"
        );
        IPriceCurve priceCurve = IPriceCurve(
            ds.collateralParams[_collateral].priceCurve
        );
        return
            priceCurve.getFeeAndUpdate(
                _collateralVCInput,
                _collateralVCBalancePost,
                _totalVCBalancePre,
                _totalVCBalancePost
            );
    }

    // should return 10**18 times the price in USD of 1 of the given _collateral
    function getPrice(address _collateral)
        public
        view
        override
        exists(_collateral)
        returns (uint256)
    {
        LibMojoDiamond.DiamondStorage storage ds = LibMojoDiamond
            .diamondStorage();
        IPriceFeed collateral_priceFeed = IPriceFeed(
            ds.collateralParams[_collateral].oracle
        );
        return collateral_priceFeed.fetchPrice_v();
    }

    // Gets the value of that collateral type, of that amount, in USD terms.
    function getValueUSD(address _collateral, uint256 _amount)
        external
        view
        override
        exists(_collateral)
        returns (uint256)
    {
        LibMojoDiamond.DiamondStorage storage ds = LibMojoDiamond
            .diamondStorage();
        uint256 decimals = ds.collateralParams[_collateral].decimals;
        uint256 price = getPrice(_collateral);
        return (price * _amount) / (10**decimals);
    }

    // Gets the value of that collateral type, of that amount, in VC terms.
    function getValueVC(address _collateral, uint256 _amount)
        external
        view
        override
        exists(_collateral)
        returns (uint256)
    {
        // uint256 price = getPrice(_collateral);
        // uint256 decimals = collateralParams[_collateral].decimals;
        // uint256 ratio = collateralParams[_collateral].ratio;
        // return (price.mul(_amount).mul(ratio).div(10**(18 + decimals)));

        // div by 10**18 for price adjustment
        // and divide by 10 ** decimals for decimal adjustment
        // do inline since this function is called often
        LibMojoDiamond.DiamondStorage storage ds = LibMojoDiamond
            .diamondStorage();
        return
            ((getPrice(_collateral) * _amount) *
                ds.collateralParams[_collateral].ratio) /
            (10**(18 + ds.collateralParams[_collateral].decimals));
    }
}
