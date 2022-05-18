// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import {LibHexaDiamond} from "./libs/LibHexaDiamond.sol";
import {IDiamondCut} from "./interfaces/IDiamondCut.sol";
import "./libs/Strings.sol";

/// @title A upgradeable stablecoin/borrowing SC protocol
/// @author abhi3700
/// @notice Any protocol can launch a protocol (stablecoin/borrowing) with a vault
contract HexaDiamond is IDiamondCut {
    using Strings for string;

    /**
     * ****************************************
     *
     * Errors
     * ****************************************
     DE0: the function does not exist
     DE1: cannot send chain's native coins directly
    */

    // Protocol diamond constructor
    /// @dev initialize protocol's data
    constructor() {

    }


    // DiamondCut Actions (Add/Replace/Remove)
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external override {
        LibHexaDiamond.enforceIsContractOwner();
        LibHexaDiamond.diamondCut(_diamondCut, _init, _calldata);
    }

    // Find facet for function that is called and execute the
    // function if a facet is found and return any value.
    fallback() external payable {
        LibHexaDiamond.DiamondStorage storage ds;
        bytes32 position = LibHexaDiamond.DIAMOND_STORAGE_POSITION;
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
