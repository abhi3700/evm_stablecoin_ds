// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import {LibMojoDiamond} from "../libs/LibMojoDiamond.sol";
import {IERC173} from "../interfaces/IERC173.sol";

/// @title A contract for the pausable Mojo protocol
/// @author abhi3700
contract PausableFacet {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    function paused() external view returns (bool paused_) {
        LibMojoDiamond.DiamondStorage storage ds = LibMojoDiamond
            .diamondStorage();
        paused_ = ds._paused;
    }

    /// @notice Pause contract
    function pause() external {
        LibMojoDiamond.checkContractOwner();
        LibMojoDiamond.whenNotPaused();

        LibMojoDiamond.DiamondStorage storage ds = LibMojoDiamond
            .diamondStorage();
        ds._paused = true;
        emit Paused(msg.sender);
    }

    /// @notice Unpause contract
    function unpause() external {
        LibMojoDiamond.checkContractOwner();
        LibMojoDiamond.whenPaused();

        LibMojoDiamond.DiamondStorage storage ds = LibMojoDiamond
            .diamondStorage();
        ds._paused = false;
        emit Unpaused(msg.sender);
    }
}
