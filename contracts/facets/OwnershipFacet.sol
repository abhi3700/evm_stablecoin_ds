// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "../libs/LibMojoDiamond.sol";
import {IERC173} from "../interfaces/IERC173.sol";

/// @title A contract for the ownable Mojo protocol
/// @author abhi3700
contract OwnershipFacet is IERC173 {
    function transferOwnership(address _newOwner) external override {
        LibMojoDiamond.checkContractOwner();
        LibMojoDiamond.setContractOwner(_newOwner);
    }

    function owner() external view override returns (address owner_) {
        owner_ = LibMojoDiamond.contractOwner();
    }
}
