// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { IJBSplitAllocator, IERC165 } from "@juicebox/interfaces/IJBSplitAllocator.sol";
import { JBSplitAllocationData } from "@juicebox/structs/JBSplitAllocationData.sol";

/**
 * @title   JBDistributor
 * @notice 
 * @dev 
 */
contract JBDistributor is IJBSplitAllocator {
    event Claimed(address indexed caller, ClaimableToken[] basket);
    event SnapshotTaken(uint256 timestamp);

    struct ClaimableToken {
        address token;
        uint256 claimableAmount;
    }

    error JBDistributor_emptyClaim();
    error JBDistributor_snapshotTooEarly();

    // The timestamp of the last snapshot
    uint256 public lastSnapshotAt;

    // The minimum delay between two snapshots
    uint256 public periodicity;

    // staked token per address
    mapping(address => uint256) public stakedBalanceOf;

    // last snapshot amounts
    ClaimableToken[] public currentClaimableBasket;
    
    // -- view --

    // return what _staker can claim now
    function currentClaimable(address _staker) external view returns (ClaimableToken[] memory) {
    }

    function getBasket() external view returns (address[] memory token, uint256[] memory claimableAmount) {
        uint256 _numberOfTokens = currentClaimableBasket.length;
        for(uint256 i; i < _numberOfTokens;) {
            token[i] = currentClaimableBasket[i].token;
            claimableAmount[i] = currentClaimableBasket[i].claimableAmount;
            unchecked {
                ++ i;
            }
        }
    }

    function supportsInterface(bytes4 interfaceId) external pure override returns (bool) {
        return interfaceId == type(IJBSplitAllocator).interfaceId
            || interfaceId == type(IERC165).interfaceId;
    }

    // -- external --

    // deposit _depositAmount of stakedToken
    function stake(uint256 _depositAmount) external {
    }

    function unstake() external {
    }

    function claim() external {
        // protection for fee on transfer token (everything in try-catch and skip them?)
        // if none -> griefing vector
    }

    function allocate(JBSplitAllocationData calldata _data) external payable override {
    }

    // -- internal --

    // take a snapshot of the claimable basket total amounts
    function takeSnapshot() internal {
    }


}
