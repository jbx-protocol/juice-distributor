// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "forge-std/Test.sol";
import "../src/JBDistributor.sol";

contract JBDistributorTest is Test {
    JBDistributor public distributor;

    address public staker;

    address public stakedToken;
    address public tokenOne;
    address public tokenTwo;
    address public tokenThree;

    function setUp() public {
        distributor = new JBDistributor();

        staker = makeAddr("staker");

        // Initialize mocks
        stakedToken = makeAddr("stakedToken");
        tokenOne = makeAddr("tokenOne");
        tokenTwo = makeAddr("tokenTwo");
        tokenThree = makeAddr("tokenThree");
        vm.etch(stakedToken, hex"69");
        vm.etch(tokenOne, hex"69");
        vm.etch(tokenTwo, hex"69");
        vm.etch(tokenThree, hex"69");
    }

    /**
     *  custom:test deposit should deposit, update balance and do not influence previously claimable amounts
     */
    function test_JBDistributor_deposit_shouldDepositAndUpdateBalance(uint256 _depositAmount) public {
        // Get the previously claimable basket amounts
        JBDistributor.ClaimableToken[] memory _claimableBefore = distributor.currentClaimable(staker);

        // get the amount already staked
        uint256 stakedBalanceBefore = distributor.stakedBalanceOf(staker);

        // -- deposit --
        vm.prank(staker);
        distributor.deposit(_depositAmount);


        // Check: claimable amounts should not have changed
        assertEq(_claimableBefore, distributor.currentClaimable(staker));

        // Check: staked balance should have increased by the deposit
        assertEq(stakedBalanceBefore + _depositAmount, distributor.stakedBalanceOf(staker));
    }

    /**
     *  custom:test takes a snapshot and create the periodic basket of tokens
     */
    function test_JBDistributor_takeSnapshot_takesSnapshotIfDelayExpired(uint256 _delay) public {

    }

    /**
     *  custom:test snapshot() reverts if called too early, after the previous snapshot has been taken
     */
    function test_JBDistributor_takeSnapshot_doNotSnapshotBeforeDelay(uint256 _delay) public {

    }

    /**
     *  custom:test After a snapshot has been taken, staker might claim their share of the basket
     */
    function test_JBDistributor_claim_shouldClaimPartOfTheBasket() public {

    }

    /**
     *  custom:test After a claim, staker need to wait for the next snapshot to claim again
     */
    function test_JBDistributor_claim_onlyClaimOnce() public {

    }

    /**
     *  custom:test Add new token to the claimable offer
     */
    function test_JBDistributor_updateBasket_shouldAddNewTokenToTheBasket() public {

    }

    /**
     *  custom:test Remove token from the claimable offer
     */
    function test_JBDistributor_updateBasket_shouldremoveTokenFromTheBasket() public {

    }

    // internal helper
    function assertEq(JBDistributor.ClaimableToken[] memory _a, JBDistributor.ClaimableToken[] memory _b) internal {
        assertEq(_a.length, _b.length);
        for (uint256 i = 0; i < _a.length; i++) {
            assertEq(_a[i].token, _b[i].token);
            assertEq(_a[i].claimableAmount, _b[i].claimableAmount);
        }
    }
}
