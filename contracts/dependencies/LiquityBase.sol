// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "../libs/math/LiquityMath.sol";
import "../interfaces/IActivePool.sol";
import "../interfaces/IDefaultPool.sol";
import "../interfaces/ILiquityBase.sol";
import "./MojoCustomBase.sol";
import "../libs/LibMojoDiamond.sol";

/*
 * Base contract for TroveManager, BorrowerOperations and StabilityPool. Contains global system constants and
 * common functions.
 */
// NOTE: contract changed to abstract as it is inherited by BO, TM, ... & not to be deployed.
abstract contract LiquityBase is
    ILiquityBase /* , MojoCustomBase */
{
    // uint constant public _100pct = 1e18; // 1e18 == 100%

    // uint constant public _110pct = 11e17; // 1.1e18 == 110%

    // // Minimum collateral ratio for individual troves
    // uint constant public MCR = 11e17; // 110%

    // // Critical system collateral ratio. If the system's total collateral ratio (TCR) falls below the CCR, Recovery Mode is triggered.
    // uint constant public CCR = 15e17; // 150%

    // // Amount of USM to be locked in gas pool on opening troves
    // uint constant public USM_GAS_COMPENSATION = 200e18;

    // // Minimum amount of net MOJO debt a must have
    // uint constant public MIN_NET_DEBT = 1800e18;
    // // uint constant public MIN_NET_DEBT = 0;

    // uint constant public PERCENT_DIVISOR = 200; // dividing by 200 yields 0.5%

    // uint constant public BORROWING_FEE_FLOOR = DECIMAL_PRECISION / 1000 * 5; // 0.5%
    // uint constant public REDEMPTION_FEE_FLOOR = DECIMAL_PRECISION / 1000 * 5; // 0.5%

    // IActivePool internal activePool;

    // IDefaultPool internal defaultPool;

    // --- Gas compensation functions ---

    // Returns the composite debt (drawn debt + gas compensation) of a trove, for the purpose of ICR calculation
    function _getCompositeDebt(uint _debt) internal pure returns (uint) {
        return (_debt + LibMojoDiamond.USM_GAS_COMPENSATION);
    }

    function _getNetDebt(uint _debt) internal pure returns (uint) {
        return (_debt - LibMojoDiamond.USM_GAS_COMPENSATION);
    }

    // Return the system's Total Virtual Coin Balance
    // Virtual Coins are a way to keep track of the system collateralization given
    // the collateral ratios of each collateral type
    function getEntireSystemColl() public view returns (uint) {
        LibMojoDiamond.DiamondStorage storage ds = LibMojoDiamond
            .diamondStorage();

        uint activeColl = ds.activePool.getVC();
        uint liquidatedColl = ds.defaultPool.getVC();

        return (activeColl + liquidatedColl);
    }

    function getEntireSystemDebt() public view override returns (uint) {
        LibMojoDiamond.DiamondStorage storage ds = LibMojoDiamond
            .diamondStorage();

        uint activeDebt = ds.activePool.getUSMDebt();
        uint closedDebt = ds.defaultPool.getUSMDebt();

        return (activeDebt + closedDebt);
    }

    function _getICRColls(newColls memory _colls, uint _debt)
        internal
        view
        returns (uint ICR)
    {
        uint totalVC = _getVCColls(_colls);
        ICR = LiquityMath._computeCR(totalVC, _debt);
    }

    function _getVC(address[] memory _tokens, uint[] memory _amounts)
        internal
        view
        returns (uint totalVC)
    {
        uint256 tokensLen = _tokens.length;
        require(tokensLen == _amounts.length, "Not same length");

        LibMojoDiamond.DiamondStorage storage ds = LibMojoDiamond
            .diamondStorage();

        for (uint256 i; i < tokensLen; ++i) {
            uint tokenVC = ds.whitelist.getValueVC(_tokens[i], _amounts[i]);
            totalVC += tokenVC;
        }
    }

    function _getVCColls(newColls memory _colls)
        internal
        view
        returns (uint VC)
    {
        uint256 tokensLen = _colls.tokens.length;

        LibMojoDiamond.DiamondStorage storage ds = LibMojoDiamond
            .diamondStorage();

        for (uint256 i; i < tokensLen; ++i) {
            uint valueVC = ds.whitelist.getValueVC(
                _colls.tokens[i],
                _colls.amounts[i]
            );
            VC += valueVC;
        }
    }

    function _getUSDColls(newColls memory _colls)
        internal
        view
        returns (uint USDValue)
    {
        uint256 tokensLen = _colls.tokens.length;

        LibMojoDiamond.DiamondStorage storage ds = LibMojoDiamond
            .diamondStorage();

        for (uint256 i; i < tokensLen; ++i) {
            uint valueUSD = ds.whitelist.getValueUSD(
                _colls.tokens[i],
                _colls.amounts[i]
            );
            USDValue += valueUSD;
        }
    }

    function _getTCR() internal view returns (uint TCR) {
        uint entireSystemColl = getEntireSystemColl();
        uint entireSystemDebt = getEntireSystemDebt();

        TCR = LiquityMath._computeCR(entireSystemColl, entireSystemDebt);
    }

    // function _checkRecoveryMode() internal view returns (bool) {
    //     uint TCR = _getTCR();
    //     return TCR < LibMojoDiamond.CCR;
    // }

    // fee and amount are denominated in dollar
    function _requireUserAcceptsFee(
        uint _fee,
        uint _amount,
        uint _maxFeePercentage
    ) internal pure {
        uint feePercentage = (_fee * LibMojoDiamond.DECIMAL_PRECISION) /
            _amount;
        require(feePercentage <= _maxFeePercentage, "Fee > max");
    }

    // checks coll has a nonzero balance of at least one token in coll.tokens
    function _CollsIsNonZero(newColls memory _colls)
        internal
        pure
        returns (bool)
    {
        uint256 tokensLen = _colls.tokens.length;
        for (uint256 i; i < tokensLen; ++i) {
            if (_colls.amounts[i] != 0) {
                return true;
            }
        }
        return false;
    }

    // Check whether or not the system *would be* in Recovery Mode, given the entire system coll and debt.
    // returns true if the system would be in recovery mode and false if not
    // function _checkPotentialRecoveryMode(uint _entireSystemColl, uint _entireSystemDebt)
    // internal
    // pure
    // returns (bool)
    // {
    //     uint TCR = LiquityMath._computeCR(_entireSystemColl, _entireSystemDebt);

    //     return TCR < LibMojoDiamond.CCR;
    // }
}
