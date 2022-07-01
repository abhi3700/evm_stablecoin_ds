// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

interface ITroveManagerLiquidations {
    function batchLiquidateTroves(
        address[] memory _troveArray,
        address _liquidator
    ) external;
}
