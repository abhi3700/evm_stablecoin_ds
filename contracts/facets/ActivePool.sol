// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "../interfaces/IActivePool.sol";
import "../interfaces/IWhitelist.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IWAsset.sol";

// import "./dependencies/SafeMath.sol";
import "../dependencies/Ownable.sol";
import "../dependencies/CheckContract.sol";
import "../dependencies/HexaCustomBase.sol";
import "../dependencies/SafeERC20.sol";

import "../libs/LibHexaDiamond.sol";

/*
 * The Active Pool holds the all collateral and USM debt (but not USM tokens) for all active troves.
 *
 * When a trove is liquidated, its collateral and USM debt are transferred from the Active Pool, to either the
 * Stability Pool, the Default Pool, or both, depending on the liquidation conditions.
 *
 */
contract ActivePool is Ownable, CheckContract, IActivePool, HexaCustomBase {
    // using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // bytes32 constant public NAME = "ActivePool";

    // address internal borrowerOperationsAddress;
    // address internal troveManagerAddress;
    // address internal stabilityPoolAddress;
    // address internal defaultPoolAddress;
    // address internal troveManagerLiquidationsAddress;
    // address internal troveManagerRedemptionsAddress;
    // address internal collSurplusPoolAddress;

    // // deposited collateral tracker. Colls is always the whitelist list of all collateral tokens. Amounts
    // newColls internal poolColl;

    // // USM Debt tracker. Tracker of all debt in the system.
    // uint256 internal aUSMDebt;

    // --- Events ---

    event BorrowerOperationsAddressChanged(
        address _newBorrowerOperationsAddress
    );
    event TroveManagerAddressChanged(address _newTroveManagerAddress);
    event ActivePoolUSMDebtUpdated(uint256 _USMDebt);
    event ActivePoolBalanceUpdated(address _collateral, uint256 _amount);
    event ActivePoolBalancesUpdated(address[] _collaterals, uint256[] _amounts);
    event CollateralsSent(
        address[] _collaterals,
        uint256[] _amounts,
        address _to
    );

    // --- Contract setters ---

    function setAddresses(
        address _borrowerOperationsAddress,
        address _troveManagerAddress,
        address _stabilityPoolAddress,
        address _defaultPoolAddress,
        address _whitelistAddress,
        address _troveManagerLiquidationsAddress,
        address _troveManagerRedemptionsAddress,
        address _collSurplusPoolAddress
    ) external onlyOwner {
        checkContract(_borrowerOperationsAddress);
        checkContract(_troveManagerAddress);
        checkContract(_stabilityPoolAddress);
        checkContract(_defaultPoolAddress);
        checkContract(_whitelistAddress);
        checkContract(_troveManagerLiquidationsAddress);
        checkContract(_troveManagerRedemptionsAddress);
        checkContract(_collSurplusPoolAddress);

        LibHexaDiamond.DiamondStorage storage ds = LibHexaDiamond
            .diamondStorage();

        ds.borrowerOperationsAddress = _borrowerOperationsAddress;
        ds.troveManagerAddress = _troveManagerAddress;
        ds.stabilityPoolAddress = _stabilityPoolAddress;
        ds.defaultPoolAddress = _defaultPoolAddress;
        ds.whitelist = IWhitelist(_whitelistAddress);
        ds.troveManagerLiquidationsAddress = _troveManagerLiquidationsAddress;
        ds.troveManagerRedemptionsAddress = _troveManagerRedemptionsAddress;
        ds.collSurplusPoolAddress = _collSurplusPoolAddress;

        emit BorrowerOperationsAddressChanged(_borrowerOperationsAddress);
        emit TroveManagerAddressChanged(_troveManagerAddress);
        emit StabilityPoolAddressChanged(_stabilityPoolAddress);
        emit DefaultPoolAddressChanged(_defaultPoolAddress);
        emit WhitelistAddressChanged(_whitelistAddress);

        // In HexaFi, we aim at upgradeability feature, so the deployer should be owner
        // & the decision is taken based on DAO voting
        // _renounceOwnership();
    }

    // --- Internal Functions ---

    // --- Getters for public variables. Required by IPool interface ---

    /*
     * Returns the collateralBalance for a given collateral
     *
     * Returns the amount of a given collateral in state. Not necessarily the contract's actual balance.
     */
    function getCollateral(address _collateral)
        public
        view
        override
        returns (uint256)
    {
        LibHexaDiamond.DiamondStorage storage ds = LibHexaDiamond
            .diamondStorage();

        return ds.apoolColl.amounts[ds.whitelist.getIndex(_collateral)];
    }

    /*
     * Returns all collateral balances in state. Not necessarily the contract's actual balances.
     */
    function getAllCollateral()
        public
        view
        override
        returns (address[] memory, uint256[] memory)
    {
        LibHexaDiamond.DiamondStorage storage ds = LibHexaDiamond
            .diamondStorage();

        return (ds.apoolColl.tokens, ds.apoolColl.amounts);
    }

    // returns the VC value of a given collateralAddress in this contract
    function getCollateralVC(address _collateral)
        external
        view
        override
        returns (uint256)
    {
        LibHexaDiamond.DiamondStorage storage ds = LibHexaDiamond
            .diamondStorage();

        return ds.whitelist.getValueVC(_collateral, getCollateral(_collateral));
    }

    /*
     * Returns the VC of the contract
     *
     * Not necessarily equal to the the contract's raw VC balance - Collateral can be forcibly sent to contracts.
     *
     * Computed when called by taking the collateral balances and
     * multiplying them by the corresponding price and ratio and then summing that
     */
    function getVC() external view override returns (uint256 totalVC) {
        LibHexaDiamond.DiamondStorage storage ds = LibHexaDiamond
            .diamondStorage();

        uint256 len = ds.apoolColl.tokens.length;
        for (uint256 i; i < len; ++i) {
            address collateral = ds.apoolColl.tokens[i];
            uint256 amount = ds.apoolColl.amounts[i];

            uint256 collateralVC = ds.whitelist.getValueVC(collateral, amount);

            totalVC += collateralVC;
        }
    }

    // Debt that this pool holds.
    function getUSMDebt() external view override returns (uint256) {
        return LibHexaDiamond.diamondStorage().aUSMDebt;
    }

    // --- Pool functionality ---

    // Internal function to send collateral to a different pool.
    function _sendCollateral(
        address _to,
        address _collateral,
        uint256 _amount
    ) internal {
        LibHexaDiamond.DiamondStorage storage ds = LibHexaDiamond
            .diamondStorage();

        uint256 index = ds.whitelist.getIndex(_collateral);
        ds.apoolColl.amounts[index] -= _amount;
        IERC20(_collateral).safeTransfer(_to, _amount);

        emit ActivePoolBalanceUpdated(_collateral, _amount);
        emit CollateralSent(_collateral, _to, _amount);
    }

    // Returns true if all payments were successfully sent. Must be called by borrower operations, trove manager/* , or stability pool */.
    function sendCollaterals(
        address _to,
        address[] calldata _tokens,
        uint256[] calldata _amounts
    ) external override returns (bool) {
        LibHexaDiamond._requireCallerIsBOorTroveMorTMLorSP();

        uint256 len = _tokens.length;
        require(len == _amounts.length, "AP:Lengths");
        uint256 thisAmount;
        for (uint256 i; i < len; ++i) {
            thisAmount = _amounts[i];
            if (thisAmount != 0) {
                _sendCollateral(_to, _tokens[i], thisAmount); // reverts if send fails
            }
        }

        if (_needsUpdateCollateral(_to)) {
            ICollateralReceiver(_to).receiveCollateral(_tokens, _amounts);
        }

        emit CollateralsSent(_tokens, _amounts, _to);

        return true;
    }

    // Returns true if all payments were successfully sent. Must be called by borrower operations, trove manager, /* or stability pool */.
    // This function als ounwraps the collaterals and sends them to _to, if they are wrapped assets. If collect rewards is set to true,
    // It also harvests rewards on the user's behalf.
    // _from is where the reward balance is, _to is where to send the tokens.
    function sendCollateralsUnwrap(
        address _from,
        address _to,
        address[] calldata _tokens,
        uint256[] calldata _amounts
    ) external override returns (bool) {
        LibHexaDiamond._requireCallerIsBOorTroveMorTMLorSP();

        uint256 tokensLen = _tokens.length;
        require(tokensLen == _amounts.length, "AP:Lengths");

        LibHexaDiamond.DiamondStorage storage ds = LibHexaDiamond
            .diamondStorage();

        for (uint256 i; i < tokensLen; ++i) {
            if (ds.whitelist.isWrapped(_tokens[i])) {
                // Collects rewards automatically for that amount and unwraps for the original borrower.
                IWAsset(_tokens[i]).unwrapFor(_from, _to, _amounts[i]);
            } else {
                _sendCollateral(_to, _tokens[i], _amounts[i]); // reverts if send fails
            }
        }
        return true;
    }

    // Function for sending single collateral. Currently only used by borrower operations unlever up functionality
    function sendSingleCollateral(
        address _to,
        address _token,
        uint256 _amount
    ) external override returns (bool) {
        LibHexaDiamond._requireCallerIsBorrowerOperations();

        _sendCollateral(_to, _token, _amount); // reverts if send fails
        return true;
    }

    // Function for sending single collateral and unwrapping. Currently only used by borrower operations unlever up functionality
    function sendSingleCollateralUnwrap(
        address _from,
        address _to,
        address _token,
        uint256 _amount
    ) external override returns (bool) {
        LibHexaDiamond._requireCallerIsBorrowerOperations();

        LibHexaDiamond.DiamondStorage storage ds = LibHexaDiamond
            .diamondStorage();

        if (ds.whitelist.isWrapped(_token)) {
            // Collects rewards automatically for that amount and unwraps for the original borrower.
            IWAsset(_token).unwrapFor(_from, _to, _amount);
        } else {
            _sendCollateral(_to, _token, _amount); // reverts if send fails
        }
        return true;
    }

    // View function that returns if the contract transferring to needs to have its balances updated.
    function _needsUpdateCollateral(address _contractAddress)
        internal
        view
        returns (bool)
    {
        LibHexaDiamond.DiamondStorage storage ds = LibHexaDiamond
            .diamondStorage();

        return ((_contractAddress == ds.defaultPoolAddress) ||
            (_contractAddress == ds.stabilityPoolAddress) ||
            (_contractAddress == ds.collSurplusPoolAddress));
    }

    // Increases the USM Debt of this pool.
    function increaseUSMDebt(uint256 _amount) external override {
        LibHexaDiamond._requireCallerIsBOorTroveM();

        LibHexaDiamond.DiamondStorage storage ds = LibHexaDiamond
            .diamondStorage();

        ds.aUSMDebt += _amount;
        emit ActivePoolUSMDebtUpdated(ds.aUSMDebt);
    }

    // Decreases the USM Debt of this pool.
    function decreaseUSMDebt(uint256 _amount) external override {
        LibHexaDiamond._requireCallerIsBOorTroveMorSP();

        LibHexaDiamond.DiamondStorage storage ds = LibHexaDiamond
            .diamondStorage();

        ds.aUSMDebt -= _amount;
        emit ActivePoolUSMDebtUpdated(ds.aUSMDebt);
    }

    //======================================================
    // `require` functions shifted to "LibHexaDiamond.sol"
    //======================================================

    // should be called by BorrowerOperations or DefaultPool
    // __after__ collateral is transferred to this contract.
    function receiveCollateral(
        address[] calldata _tokens,
        uint256[] calldata _amounts
    ) external override {
        LibHexaDiamond._requireCallerIsBorrowerOperationsOrDefaultPool();

        LibHexaDiamond.DiamondStorage storage ds = LibHexaDiamond
            .diamondStorage();

        LibHexaDiamond.newColls memory _poolColl = ds.apoolColl;

        ds.apoolColl.amounts = _leftSumColls(_poolColl, _tokens, _amounts);
        emit ActivePoolBalancesUpdated(_tokens, _amounts);
    }

    // Adds collateral type from whitelist.
    function addCollateralType(address _collateral) external override {
        LibHexaDiamond._requireCallerIsWhitelist();

        LibHexaDiamond.DiamondStorage storage ds = LibHexaDiamond
            .diamondStorage();

        ds.apoolColl.tokens.push(_collateral);
        ds.apoolColl.amounts.push(0);
    }

    //======================================================
    // Utils
    //======================================================
    function getName() external pure returns (string memory) {
        return "ActivePool";
    }
}
