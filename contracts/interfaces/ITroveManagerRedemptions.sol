// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

interface ITroveManagerRedemptions {
    function redeemCollateral(
        uint256 _USMamount,
        uint256 _USMMaxFee,
        address _firstRedemptionHint,
        address _upperPartialRedemptionHint,
        address _lowerPartialRedemptionHint,
        uint256 _partialRedemptionHintNICR,
        uint256 _maxIterations,
        // uint256 _maxFeePercentage,
        address _redeemSender
    ) external;
}
