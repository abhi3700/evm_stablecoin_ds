// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "./IERC20.sol";
import "./IERC2612.sol";

interface IMOJOToken is IERC20, IERC2612 {
    function sendToSYETI(address _sender, uint256 _amount) external;

    function getDeploymentStartTime() external view returns (uint256);
}
