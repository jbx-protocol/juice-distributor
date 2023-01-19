// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @title   JBDistributor
 * @notice 
 * @dev 
 */
contract JBDistributor {
    struct ClaimableToken {
        address token;
        uint256 claimableAmount;
    }

    // staked token per address
    mapping(address => uint256) public stakedBalanceOf;

    // last snapshot amounts
    ClaimableToken[] public currentClaimableBasket;
    
    // -- view --

    // return what _staker can claim now
    function currentClaimable(address _staker) external view returns (ClaimableToken[] memory) {
    }


    // deposit _depositAmount of stakedToken
    function deposit(uint256 _depositAmount) external {
    }

}
