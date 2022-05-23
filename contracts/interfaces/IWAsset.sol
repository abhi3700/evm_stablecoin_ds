// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;


// Wrapped Asset
interface IWAsset  {

    function wrap(uint _amount, address _from, address _to, address _rewardOwner) external;
    
    function unwrapFor(address _from, address _to, uint amount) external;

    function updateReward(address from, address to, uint amount) external;

    function claimReward(address _to) external;

    function claimRewardFor(address _for) external;

    function getPendingRewards(address _for) external returns (address[] memory, uint[] memory);

    function endTreasuryReward(address _to, uint _amount) external;
}
