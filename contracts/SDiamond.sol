// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibCFDiamond} from "./libraries/LibCFDiamond.sol";
import {IDiamondCut} from "./interfaces/IDiamondCut.sol";
import "./libraries/Strings.sol";

/// @title A upgradeable stablecoin/borrowing SC
/// @author abhi3700
/// @notice Any protocol can launch a protocol (stablecoin/borrowing) with a vault
contract SDiamond is IDiamondCut {
    using Strings for string;


}
