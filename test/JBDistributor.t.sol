// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "forge-std/Test.sol";
import "../src/JBDistributor.sol";

contract JBDistributorTest is Test {
    event Claimed(address indexed caller, JBDistributor.ClaimableToken[] basket);
    event SnapshotTaken(uint256 timestamp);

    ForTest_JBDistributor public distributor;

    address public staker;

    address public stakedToken;
    address public tokenOne;
    address public tokenTwo;
    address public tokenThree;

    JBDistributor.ClaimableToken[] previousBasket;

    function setUp() public {
        staker = makeAddr("staker");

        // Initialize a distributor and a first snapshot
        distributor = new ForTest_JBDistributor();

        // Initialize mocks
        stakedToken = makeAddr("stakedToken");
        tokenOne = makeAddr("tokenOne");
        tokenTwo = makeAddr("tokenTwo");
        tokenThree = makeAddr("tokenThree");
        vm.etch(stakedToken, hex"69");
        vm.etch(tokenOne, hex"69");
        vm.etch(tokenTwo, hex"69");
        vm.etch(tokenThree, hex"69");

        // Mock a previous snapshot
        previousBasket.push(JBDistributor.ClaimableToken(tokenOne, 100));
        previousBasket.push(JBDistributor.ClaimableToken(tokenTwo, 200));
        distributor.overrideClaimableBasket(previousBasket);
        distributor.overrideSnapshotTimestamp(block.timestamp);
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
     *  custom:test when allocating a new token (tokenThree), if the delay has passed, a new snapshot is taken with
     *              a basket made of the new token and any leftover of the previous basket.
     */
    function test_JBDistributor_allocate_takesSnapshotIfDelayExpired(uint256 _currentTimestamp) public {
        // Set the current timestamp after the claiming period
        vm.assume(_currentTimestamp > block.timestamp + distributor.periodicity());
        vm.warp(_currentTimestamp);

        // Mock an allocation data
        JBSplitAllocationData memory _data = JBSplitAllocationData({
            token: tokenThree,
            amount: 3000,
            decimals: 18,
            projectId: 0,
            group: 1,
            split: JBSplit({
                allocator: address(distributor),
                percent: 0,
                recipient: address(0)
            })
        });

        // Mock the ERC20 balances
        vm.mockCall(tokenOne, abi.encodeWithSelector(IERC20.balanceOf.selector, address(distributor)), abi.encode(1000));
        vm.mockCall(tokenTwo, abi.encodeWithSelector(IERC20.balanceOf.selector, address(distributor)), abi.encode(2000));
        vm.mockCall(tokenThree, abi.encodeWithSelector(IERC20.balanceOf.selector, address(distributor)), abi.encode(3000));

        // Check: correct event?
        emit SnapshotTaken(_currentTimestamp);
        vm.expectEmit(true, true, true, true);

        // -- take snapshot --
        distributor.allocate(_data);

        // Check: snapshot timestamp should have been updated
        assertEq(_currentTimestamp, distributor.lastSnapshotAt());

        // Check: claimable basket should have been updated
        JBDistributor.ClaimableToken[] memory newBasket = new JBDistributor.ClaimableToken[](3);
        newBasket[0] = JBDistributor.ClaimableToken(tokenOne, 1000);
        newBasket[1] = JBDistributor.ClaimableToken(tokenTwo, 2000);
        newBasket[2] = JBDistributor.ClaimableToken(tokenThree, 3000);

        for(uint256 i; i < newBasket.length; i++) {
            (address _token, uint256 _amount) = distributor.currentClaimableBasket(i);
            assertEq(newBasket[i].token, _token);
            assertEq(newBasket[i].claimableAmount, _amount);
        }
    }

    /**
     *  custom:test allocate does not take a new snapshot but add the incoming token to the pending basket
     */
    function test_JBDistributor_allocate_doNotSnapshotBeforeDelay(uint256 _currentTimestamp) public {

    }

    /**
     *  custom:test When a snapshot is taken, tokens with a zero balance are removed from the basket
     */
    function test_JBDistributor_allocate_shouldRemoveTokenWithEmptyBalanceDuringSnapshot() public {

        // Delay has expired
        distributor.overrideSnapshotTimestamp(block.timestamp);
        vm.warp(block.timestamp + distributor.periodicity() + 1);

        // Mock an allocation data
        JBSplitAllocationData memory _data = JBSplitAllocationData({
            token: tokenThree,
            amount: 3000,
            decimals: 18,
            projectId: 0,
            group: 1,
            split: JBSplit({
                allocator: address(distributor),
                percent: 0,
                recipient: address(0)
            })
        });

        // Mock the ERC20 balances
        vm.mockCall(tokenOne, abi.encodeWithSelector(IERC20.balanceOf.selector, address(distributor)), abi.encode(1000));
        vm.mockCall(tokenTwo, abi.encodeWithSelector(IERC20.balanceOf.selector, address(distributor)), abi.encode(0));
        vm.mockCall(tokenThree, abi.encodeWithSelector(IERC20.balanceOf.selector, address(distributor)), abi.encode(3000));

        // Check: correct event?
        emit SnapshotTaken(_currentTimestamp);
        vm.expectEmit(true, true, true, true);

        // -- take snapshot --
        distributor.allocate(_data);

        // Check: snapshot timestamp should have been updated
        assertEq(_currentTimestamp, distributor.lastSnapshotAt());

        // Check: claimable basket should have been updated
        JBDistributor.ClaimableToken[] memory newBasket = new JBDistributor.ClaimableToken[](2);
        newBasket[0] = JBDistributor.ClaimableToken(tokenOne, 1000);
        newBasket[1] = JBDistributor.ClaimableToken(tokenThree, 3000);

        for(uint256 i; i < newBasket.length; i++) {
            (address _token, uint256 _amount) = distributor.currentClaimableBasket(i);
            assertEq(newBasket[i].token, _token);
            assertEq(newBasket[i].claimableAmount, _amount);
        }
    }

    /**
     *  custom:test After a snapshot has been taken, staker might claim their share of the basket
     */
    function test_JBDistributor_claim_shouldClaimPartOfTheBasketOnlyOnce() public {
        // Delay has expired
        distributor.overrideSnapshotTimestamp(block.timestamp - distributor.periodicity());

        // Mock the token transfers
        vm.mockCall(tokenOne, abi.encodeWithSelector(IERC20.transfer.selector, staker, 100), abi.encode(true));
        vm.mockCall(tokenTwo, abi.encodeWithSelector(IERC20.transfer.selector, staker, 200), abi.encode(true));
        vm.mockCall(tokenThree, abi.encodeWithSelector(IERC20.transfer.selector, staker, 300), abi.encode(true));

        // Check: correct call to token transfers?
        vm.expectCall(tokenOne, abi.encodeWithSelector(IERC20.transfer.selector, staker, 100));
        vm.expectCall(tokenTwo, abi.encodeWithSelector(IERC20.transfer.selector, staker, 200));
        vm.expectCall(tokenThree, abi.encodeWithSelector(IERC20.transfer.selector, staker, 300));

        // Check: correct event?
        emit Claimed(staker, previousBasket);
        vm.expectEmit(true, true, true, true);

        // -- claim --
        vm.prank(staker);
        distributor.claim();

        // Check: staker has nothing to claim left
        assertEq(new JBDistributor.ClaimableToken[](0), distributor.currentClaimable(staker));

        // Check: cannot claim a second time
        vm.expectRevert(abi.encodeWithSelector(JBDistributor.JBDistributor_emptyClaim.selector));
        vm.prank(staker);
        distributor.claim();
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

contract ForTest_JBDistributor is JBDistributor {
    function overrideClaimableBasket(JBDistributor.ClaimableToken[] memory _newBasket) public {
        delete currentClaimableBasket;

        for(uint256 i = 0; i < currentClaimableBasket.length; i++)
            currentClaimableBasket.push(_newBasket[i]);
    }

    function overrideSnapshotTimestamp(uint256 _newTimestamp) public {
        lastSnapshotAt = _newTimestamp;
    }
}