// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "./IPriceFeed.sol";

interface ILiquityBase {
    function getEntireSystemDebt()
        external
        view
        returns (uint entireSystemDebt);
}
