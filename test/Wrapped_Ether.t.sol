// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {WETH} from "../src/Wrapped_Ether_flattened.sol";
import "forge-std/console.sol";

contract WETH_test is Test {
    WETH public weth;

    event Stake(address indexed _from, uint256 indexed _amount);
    event Withdraw(address indexed _to, uint256 indexed _amount);

    address user1 = makeAddr("user1");
    address user2 = makeAddr("user2");

    function setUp() public {
        weth = new WETH();
    }

    function test_stake() public {
        vm.startPrank(user1);

        deal(user1, 1 ether);
        uint weth_bfBalance = address(weth).balance;
        uint user1_weth_bfBalance = weth.balanceOf(user1);

        // 測項 3: deposit 應該要 emit Deposit event
        vm.expectEmit();
        emit Stake(user1, 1 ether);
        weth.stake{value: 1 ether}();

        uint weth_afBalance = address(weth).balance;
        uint user1_weth_afBalance = weth.balanceOf(user1);

        // 測項 1: deposit 應該將與 msg.value 相等的 ERC20 token mint 給 user
        assertEq(user1_weth_afBalance - user1_weth_bfBalance, 10 ** 18);

        // 測項 2: deposit 應該將 msg.value 的 ether 轉入合約
        assertEq(weth_afBalance - weth_bfBalance, 1 ether);

        vm.stopPrank();
    }

    function test_withdraw() public {
        vm.startPrank(user1);

        deal(user1, 1 ether);
        weth.stake{value: 1 ether}();

        uint totalSupply_bf = weth.totalSupply();
        uint user1_bfBalance = user1.balance;

        // 測項 6: withdraw 應該要 emit Withdraw event
        // vm.expectEmit();
        // emit Withdraw(user1, 10 ** 18);
        weth.withdraw(10 ** 18);

        uint totalSupply_af = weth.totalSupply();
        uint user1_afBalance = user1.balance;

        // 測項 4: withdraw 應該要 burn 掉與 input parameters 一樣的 erc20 token
        assertEq(totalSupply_bf - totalSupply_af, 10 ** 18);

        // 測項 5: withdraw 應該將 burn 掉的 erc20 換成 ether 轉給 user
        assertEq(user1_afBalance - user1_bfBalance, 1 ether);

        vm.stopPrank();
    }

    function test_transfer() public {
        vm.startPrank(user1);

        deal(address(weth), user1, 10 ** 18);
        weth.transfer(address(user2), 10 ** 18);

        // - 測項 7: transfer 應該要將 erc20 token 轉給別人
        assertEq(weth.balanceOf(user1), 0);
        assertEq(weth.balanceOf(user2), 10 ** 18);

        vm.stopPrank();
    }

    function test_approve() public {
        vm.startPrank(user1);

        weth.approve(user2, 10 ** 18);
        // - 測項 8: approve 應該要給他人 allowance
        assertEq(weth.allowance(user1, user2), 10 ** 18);

        vm.stopPrank();
    }

    function test_transferFrom() public {
        deal(address(weth), user1, 10 ** 18);
        vm.prank(user1);
        weth.approve(user2, 10 ** 18);

        // - 測項 9: transferFrom 應該要可以使用他人的 allowance
        assertEq(weth.allowance(user1, user2), 10 ** 18);

        vm.prank(user2);
        weth.transferFrom(user1, user2, 10 ** 18);

        // - 測項 10: transferFrom 後應該要減除用完的 allowance
        assertEq(weth.allowance(user1, user2), 0);

        assertEq(weth.balanceOf(user1), 0);
        assertEq(weth.balanceOf(user2), 10 ** 18);
    }
}
