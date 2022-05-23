// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import {IDiamondCut} from "../interfaces/IDiamondCut.sol";

library LibHexaDiamond {
    /**
     * ****************************************
     *
     * Errors
     * ****************************************
     LIBE0: the caller is not a owner
     LIBE1: HexaFi SC was not paused
     LIBE2: HexaFi SC was paused
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
        keccak256("hexa.finance.diamond.storage");

    struct FacetAddressAndPosition {
        address facetAddress;
        uint96 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
    }

    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint256 facetAddressPosition; // position of facetAddress in facetAddresses array
    }

    struct newColls {
        // tokens and amounts should be the same length
        address[] tokens;
        uint256[] amounts;
    }


    struct DiamondStorage {
        // maps function selector to the facet address and
        // the position of the selector in the facetFunctionSelectors.selectors array
        mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
        // maps facet addresses to function selectors
        mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
        // facet addresses
        address[] facetAddresses;
        // owner of the contract & project owner
        address contractOwner;
        // paused of the contract
        bool _paused;
        // chainId
        uint256 chainId;

        // addresses
        address borrowerOperationsAddress;
        address troveManagerAddress;
        address activePoolAddress;
        address stabilityPoolAddress;
        address defaultPoolAddress;
        address troveManagerLiquidationsAddress;
        address troveManagerRedemptionsAddress;
        address collSurplusPoolAddress;
        address yetiFinanceTreasury;
        
        // deposited collateral tracker. Colls is always the whitelist list of all collateral tokens. Amounts 
        newColls poolColl;

        // USM Debt tracker. Tracker of all debt in the system (active + default + stability). 
        // DONE: confirm if this is the sum of all pools or each pool needs to have one.
        uint256 aUSMDebt;       // USM debt of active pool
        uint256 dUSMDebt;       // USM debt of default pool
        uint256 sUSMDebt;       // USM debt of stability pool



        // TODO: Please add new members from end of struct
    }

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

    function enforceIsContractOwner() internal view {
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

    // --- 'require' functions | "ActivePool.sol"---

    function _requireCallerIsBOorTroveMorTMLorSP() internal view {
        LibHexaDiamond.DiamondStorage storage ds = LibHexaDiamond.diamondStorage();
        
        if (
            msg.sender != ds.borrowerOperationsAddress &&
            msg.sender != ds.troveManagerAddress &&
            msg.sender != ds.stabilityPoolAddress &&
            msg.sender != ds.troveManagerLiquidationsAddress &&
            msg.sender != ds.troveManagerRedemptionsAddress) {
                _revertWrongFuncCaller();
            }
    }

    function _requireCallerIsBorrowerOperationsOrDefaultPool() internal view {
        LibHexaDiamond.DiamondStorage storage ds = LibHexaDiamond.diamondStorage();
        
        if (msg.sender != ds.borrowerOperationsAddress &&
            msg.sender != ds.defaultPoolAddress) {
                _revertWrongFuncCaller();
            }
    }

    function _requireCallerIsBorrowerOperations() internal view {
        LibHexaDiamond.DiamondStorage storage ds = LibHexaDiamond.diamondStorage();
        
        if (msg.sender != ds.borrowerOperationsAddress) {
                _revertWrongFuncCaller();
            }
    }

    function _requireCallerIsBOorTroveMorSP() internal view {
        LibHexaDiamond.DiamondStorage storage ds = LibHexaDiamond.diamondStorage();
        
        if (msg.sender != ds.borrowerOperationsAddress &&
            msg.sender != ds.troveManagerAddress &&
            msg.sender != ds.stabilityPoolAddress &&
            msg.sender != ds.troveManagerRedemptionsAddress) {
                _revertWrongFuncCaller();
            }
    }

    function _requireCallerIsBOorTroveM() internal view {
        LibHexaDiamond.DiamondStorage storage ds = LibHexaDiamond.diamondStorage();
        
        if (msg.sender != ds.borrowerOperationsAddress &&
            msg.sender != ds.troveManagerAddress) {
                _revertWrongFuncCaller();
            }
    }

    function _requireCallerIsWhitelist() internal view {
        if (msg.sender != address(whitelist)) {         // TODO: whitelist?
            _revertWrongFuncCaller();
        }
    }

    function _revertWrongFuncCaller() internal view {
        revert("AP: External caller not allowed");
    }

    

}
