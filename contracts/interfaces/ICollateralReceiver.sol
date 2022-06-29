// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

interface ICollateralReceiver {
    function receiveCollateral(
        address[] memory _tokens,
        uint256[] memory _amounts
    ) external;
}
