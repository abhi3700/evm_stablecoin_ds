// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import {LibMojoDiamond} from "./libs/LibMojoDiamond.sol";
import {IDiamondCut} from "./interfaces/IDiamondCut.sol";
import "./interfaces/IActivePool.sol";
import "./interfaces/IDefaultPool.sol";
import "./libs/Strings.sol";
import "./dependencies/CheckContract.sol";

/// @title A upgradeable Mojo protocol
/// @author abhi3700
/// @notice Any protocol can launch a protocol (stablecoin/borrowing)
contract MojoDiamond is IDiamondCut, CheckContract {
    using Strings for string;

    /**
     * ****************************************
     *
     * Errors
     * ****************************************
     DE0: the function does not exist
     DE1: cannot send chain's native coins directly
    */

    event ActivePoolAddressChanged(address _activePoolAddress);
    event DefaultPoolAddressChanged(address _defaultPoolAddress);
    // event StabilityPoolAddressChanged(address _stabilityPoolAddress);
    event WhitelistAddressChanged(address _whitelistAddres);
    event GasPoolAddressChanged(address _gasPoolAddress);
    event CollSurplusPoolAddressChanged(address _collSurplusPoolAddress);
    event PriceFeedAddressChanged(address _newPriceFeedAddress);
    event SortedTrovesAddressChanged(address _sortedTrovesAddress);
    event USMTokenAddressChanged(address _usmTokenAddress);
    event MOJOTokenAddressChanged(address _mojoTokenAddress);
    event sMOJOAddressChanged(address _sMOJOAddress);
    event BorrowerOperationsAddressChanged(
        address _borrowerOperationsAddressChanged
    );
    event TroveManagerAddressChanged(address _newTroveManagerAddress);

    // Protocol diamond constructor
    /// @dev initialize protocol's data
    constructor(address _mojoCustomBaseAddress, FacetCut[] memory _diamondCut) {
        // set whitelist address - `whitelist`, `whitelistAddress`
        // set deployer as the contract owner
        LibMojoDiamond.setContractOwner(msg.sender);

        LibMojoDiamond.DiamondStorage storage ds = LibMojoDiamond
            .diamondStorage();

        // Set chain ID
        ds.chainId = block.chainid;

        // Set the deployed MojoCustomBase contract address
        ds.allAddresses.mojoCustomBaseAddress = _mojoCustomBaseAddress;

        // set diamond cuts
        LibMojoDiamond.diamondCut(_diamondCut, address(0), "");
    }

    /// @notice set Addresses of facets
    function setAddresses(
        address _activePoolAddress,
        address _defaultPoolAddress,
        // address _stabilityPoolAddress,
        address _whitelistAddress,
        address _gasPoolAddress,
        address _collSurplusPoolAddress,
        address _sortedTrovesAddress,
        address _usmTokenAddress,
        address _mojoTokenAddress,
        address _sMOJOAddress,
        address _borrowerOperationsAddress,
        address _troveManagerAddress
    ) external {
        LibMojoDiamond.checkContractOwner();
        LibMojoDiamond.DiamondStorage storage ds = LibMojoDiamond
            .diamondStorage();
        require(ds.chainId != 0, "contract not yet deployed");
        require(!ds.addressesSet, "addresses already set");
        // This makes impossible to open a trove with zero withdrawn USM
        require(LibMojoDiamond.MIN_NET_DEBT != 0, "BO:MIN_NET_DEBT==0");

        checkContract(_activePoolAddress);
        checkContract(_defaultPoolAddress);
        // checkContract(_stabilityPoolAddress);
        checkContract(_whitelistAddress);
        checkContract(_gasPoolAddress);
        checkContract(_collSurplusPoolAddress);
        checkContract(_sortedTrovesAddress);
        checkContract(_usmTokenAddress);
        checkContract(_mojoTokenAddress);
        checkContract(_sMOJOAddress);
        checkContract(_borrowerOperationsAddress);
        checkContract(_troveManagerAddress);

        ds.allAddresses.activePoolAddress = _activePoolAddress;
        ds.allAddresses.defaultPoolAddress = _defaultPoolAddress;
        // ds.allAddresses.stabilityPoolAddress = _stabilityPoolAddress;
        ds.allAddresses.whitelistAddress = _whitelistAddress;
        ds.allAddresses.gasPoolAddress = _gasPoolAddress;
        ds.allAddresses.collSurplusPoolAddress = _collSurplusPoolAddress;
        ds.allAddresses.sortedTroveAddress = _sortedTrovesAddress;
        ds.allAddresses.usmTokenAddress = _usmTokenAddress;
        ds.allAddresses.mojoTokenAddress = _mojoTokenAddress;
        ds.allAddresses.sMOJOAddress = _sMOJOAddress;
        ds.allAddresses.borrowerOperationsAddress = _borrowerOperationsAddress;
        ds.allAddresses.troveManagerAddress = _troveManagerAddress;
        // TODO: Add these as well
        // ds
        //     .allAddresses
        //     .troveManagerLiquidationsAddress = _troveManagerLiquidationsAddress;
        // ds
        //     .allAddresses
        //     .troveManagerRedemptionsAddress = _troveManagerRedemptionsAddress;

        ds.addressesSet = true;
        ds.deploymentTime = block.timestamp;

        // TODO: Set the interfaces
        /*         ds.activePool = IActivePool(_activePoolAddress);
        ds.defaultPool = IDefaultPool(_defaultPoolAddress);
        ds.whitelist = IWhitelist(_whitelistAddress);
        ds.collSurplusPool = ICollSurplusPool(_collSurplusPoolAddress);
        ds.whitelist = IWhitelist(_whitelistAddress); */

        // events
        emit ActivePoolAddressChanged(_activePoolAddress);
        emit DefaultPoolAddressChanged(_defaultPoolAddress);
        // emit StabilityPoolAddressChanged(_stabilityPoolAddress);
        emit WhitelistAddressChanged(_whitelistAddress);
        emit GasPoolAddressChanged(_gasPoolAddress);
        emit CollSurplusPoolAddressChanged(_collSurplusPoolAddress);
        emit SortedTrovesAddressChanged(_sortedTrovesAddress);
        emit USMTokenAddressChanged(_usmTokenAddress);
        emit MOJOTokenAddressChanged(_mojoTokenAddress);
        emit sMOJOAddressChanged(_sMOJOAddress);
        emit BorrowerOperationsAddressChanged(_borrowerOperationsAddress);
        emit TroveManagerAddressChanged(_troveManagerAddress);
    }

    /// @notice Set MojoCustomBase contract
    /// @dev set contract address after updating the logic inside contract
    function setMojoCustomBase(address _mojoCustomBaseAddress) external {
        LibMojoDiamond.checkContractOwner();
        LibMojoDiamond.DiamondStorage storage ds = LibMojoDiamond
            .diamondStorage();
        require(ds.chainId != 0, "contract not yet deployed");
        require(!ds.addressesSet, "addresses already set");
        checkContract(_mojoCustomBaseAddress);

        ds.allAddresses.mojoCustomBaseAddress = _mojoCustomBaseAddress;
    }

    // DiamondCut Actions (Add/Replace/Remove)
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external override {
        LibMojoDiamond.checkContractOwner();
        LibMojoDiamond.diamondCut(_diamondCut, _init, _calldata);
    }

    // Find facet for function that is called and execute the
    // function if a facet is found and return any value.
    fallback() external payable {
        LibMojoDiamond.DiamondStorage storage ds;
        bytes32 position = LibMojoDiamond.DIAMOND_STORAGE_POSITION;
        // get diamond storage
        assembly {
            ds.slot := position
        }
        // get facet from function selector
        address facet = ds.selectorToFacetAndPosition[msg.sig].facetAddress;
        require(facet != address(0), "DE0");

        // Execute external function from facet using delegatecall and return any value.
        assembly {
            // copy function selector and any arguments
            calldatacopy(0, 0, calldatasize())
            // execute function call using the facet
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            // get any return value
            returndatacopy(0, 0, returndatasize())
            // return any return value or error back to the caller
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    // call when receiving native coin with send() / transfer()
    receive() external payable {
        revert("DE1");
    }
}
