// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "../interfaces/IDefaultPool.sol";
import "../interfaces/IActivePool.sol";
import "../interfaces/IWhitelist.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IWAsset.sol";
// import "./dependencies/SafeMath.sol";
import "../dependencies/Ownable.sol";
import "../dependencies/CheckContract.sol";
import "../dependencies/MojoCustomBase.sol";
import "../dependencies/SafeERC20.sol";

import "../libs/LibMojoDiamond.sol";

/*
 * The Default Pool holds the collateral and USM debt (but not USM tokens) from liquidations that have been redistributed
 * to active troves but not yet "applied", i.e. not yet recorded on a recipient active trove's struct.
 *
 * When a trove makes an operation that applies its pending collateral and USM debt, its pending collateral and USM debt is moved
 * from the Default Pool to the Active Pool.
 */
contract DefaultPool is Ownable, CheckContract, IDefaultPool, MojoCustomBase {
    // using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // string public constant NAME = "DefaultPool";

    // address internal troveManagerAddress;
    // address internal activePoolAddress;
    // address internal whitelistAddress;
    // address internal hexaFinanceTreasury;

    // // deposited collateral tracker. Colls is always the whitelist list of all collateral tokens. Amounts
    // newColls internal dpoolColl;

    // uint256 internal dUSMDebt;

    // --- Events ---

    event TroveManagerAddressChanged(address _newTroveManagerAddress);
    event DefaultPoolUSMDebtUpdated(uint256 _USMDebt);
    event DefaultPoolBalanceUpdated(address _collateral, uint256 _amount);
    event DefaultPoolBalancesUpdated(
        address[] _collaterals,
        uint256[] _amounts
    );

    // --- Dependency setters ---

    function setAddresses(
        address _troveManagerAddress,
        address _activePoolAddress,
        address _whitelistAddress,
        address _hexaTreasuryAddress
    ) external onlyOwner {
        checkContract(_troveManagerAddress);
        checkContract(_activePoolAddress);
        checkContract(_whitelistAddress);
        checkContract(_hexaTreasuryAddress);

        LibMojoDiamond.DiamondStorage storage ds = LibMojoDiamond
            .diamondStorage();

        ds.troveManagerAddress = _troveManagerAddress;
        ds.activePoolAddress = _activePoolAddress;
        ds.whitelist = IWhitelist(_whitelistAddress);
        ds.whitelistAddress = _whitelistAddress;
        ds.hexaFinanceTreasury = _hexaTreasuryAddress;

        emit TroveManagerAddressChanged(_troveManagerAddress);
        emit ActivePoolAddressChanged(_activePoolAddress);

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
        LibMojoDiamond.DiamondStorage storage ds = LibMojoDiamond
            .diamondStorage();

        return ds.dpoolColl.amounts[ds.whitelist.getIndex(_collateral)];
    }

    /*
     * Returns all collateral balances in state. Not necessarily the contract's actual balances.
     */
    function getAllCollateral()
        external
        view
        override
        returns (address[] memory, uint256[] memory)
    {
        LibMojoDiamond.DiamondStorage storage ds = LibMojoDiamond
            .diamondStorage();

        return (ds.dpoolColl.tokens, ds.dpoolColl.amounts);
    }

    // returns the VC value of a given collateralAddress in this contract
    function getCollateralVC(address _collateral)
        external
        view
        override
        returns (uint256)
    {
        LibMojoDiamond.DiamondStorage storage ds = LibMojoDiamond
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
        LibMojoDiamond.DiamondStorage storage ds = LibMojoDiamond
            .diamondStorage();

        uint256 tokensLen = ds.dpoolColl.tokens.length;
        for (uint256 i; i < tokensLen; ++i) {
            address collateral = ds.dpoolColl.tokens[i];
            uint256 amount = ds.dpoolColl.amounts[i];

            uint256 collateralVC = ds.whitelist.getValueVC(collateral, amount);
            totalVC += collateralVC;
        }
    }

    // Debt that this pool holds.
    function getUSMDebt() external view override returns (uint256) {
        return LibMojoDiamond.diamondStorage().dUSMDebt;
    }

    // Internal function to send collateral to a different pool.
    function _sendCollateral(address _collateral, uint256 _amount) internal {
        LibMojoDiamond.DiamondStorage storage ds = LibMojoDiamond
            .diamondStorage();

        address activePool = ds.activePoolAddress;
        uint256 index = ds.whitelist.getIndex(_collateral);
        ds.dpoolColl.amounts[index] += _amount;

        IERC20(_collateral).safeTransfer(activePool, _amount);

        emit DefaultPoolBalanceUpdated(_collateral, _amount);
        emit CollateralSent(_collateral, activePool, _amount);
    }

    // Returns true if all payments were successfully sent. Must be called by borrower operations, trove manager, or stability pool.
    function sendCollsToActivePool(
        address[] calldata _tokens,
        uint256[] calldata _amounts,
        address _borrower
    ) external override {
        LibMojoDiamond._requireCallerIsTroveManager();

        uint256 tokensLen = _tokens.length;
        require(tokensLen == _amounts.length, "DP:Length mismatch");

        LibMojoDiamond.DiamondStorage storage ds = LibMojoDiamond
            .diamondStorage();

        uint256 thisAmounts;
        address thisToken;
        for (uint256 i; i < tokensLen; ++i) {
            thisAmounts = _amounts[i];
            if (thisAmounts != 0) {
                thisToken = _tokens[i];

                // If asset is wrapped, then that means it came from the active pool (originally) and we need to update rewards from
                // the treasury which would have owned the rewards, to the new borrower who will be accumulating this new
                // reward.
                if (ds.whitelist.isWrapped(thisToken)) {
                    // This call claims the tokens for the treasury and also transfers them to the default pool as an intermediary so
                    // that it can transfer.
                    IWAsset(thisToken).endTreasuryReward(
                        address(this),
                        thisAmounts
                    );
                    // Call transfer
                    _sendCollateral(thisToken, thisAmounts);
                    // Then finally transfer rewards to the borrower
                    IWAsset(thisToken).updateReward(
                        address(this),
                        _borrower,
                        thisAmounts
                    );
                } else {
                    // Otherwise just send.
                    _sendCollateral(thisToken, thisAmounts);
                }
            }
        }
        IActivePool(ds.activePoolAddress).receiveCollateral(_tokens, _amounts);
    }

    // Increases the USM Debt of this pool.
    function increaseUSMDebt(uint256 _amount) external override {
        LibMojoDiamond._requireCallerIsTroveManager();

        LibMojoDiamond.DiamondStorage storage ds = LibMojoDiamond
            .diamondStorage();

        ds.dUSMDebt += _amount;
        emit DefaultPoolUSMDebtUpdated(ds.dUSMDebt);
    }

    // Decreases the USM Debt of this pool.
    function decreaseUSMDebt(uint256 _amount) external override {
        LibMojoDiamond._requireCallerIsTroveManager();
        LibMojoDiamond.DiamondStorage storage ds = LibMojoDiamond
            .diamondStorage();

        ds.dUSMDebt = _amount;
        emit DefaultPoolUSMDebtUpdated(ds.dUSMDebt);
    }

    //======================================================
    // `require` functions shifted to "LibMojoDiamond.sol"
    //======================================================

    // Should be called by ActivePool
    // __after__ collateral is transferred to this contract from Active Pool
    function receiveCollateral(
        address[] calldata _tokens,
        uint256[] calldata _amounts
    ) external override {
        LibMojoDiamond._requireCallerIsActivePool();
        LibMojoDiamond.DiamondStorage storage ds = LibMojoDiamond
            .diamondStorage();

        ds.dpoolColl.amounts = _leftSumColls(ds.dpoolColl, _tokens, _amounts);
        emit DefaultPoolBalancesUpdated(_tokens, _amounts);
    }

    // Adds collateral type from whitelist.
    function addCollateralType(address _collateral) external override {
        LibMojoDiamond._requireCallerIsWhitelist();
        LibMojoDiamond.DiamondStorage storage ds = LibMojoDiamond
            .diamondStorage();

        ds.dpoolColl.tokens.push(_collateral);
        ds.dpoolColl.amounts.push(0);
    }

    //======================================================
    // Utils
    //======================================================
    function getName() external pure returns (string memory) {
        return "DefaultPool";
    }
}
