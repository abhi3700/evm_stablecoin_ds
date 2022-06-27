// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

interface IBaseOracle {
    /// @dev Return the value of the given input as USD per unit.
    /// @param token The ERC-20 token to check the value.
    function getPrice(address token) external view returns (uint256);
}
