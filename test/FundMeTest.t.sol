// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../src/FundMe.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";
import {DeployFundMe} from "../script/DeployFundMe.s.sol";
import {StdCheats} from "forge-std/StdCheats.sol";

contract FundMeTest is StdCheats, Test {
    FundMe public fundMe;
    HelperConfig public helperConfig;

    uint256 public constant SEND_VALUE = 0.1 ether; // just a value to make sure we are sending enough!
    uint256 public constant STARTING_USER_BALANCE = 10 ether;
    uint256 public constant GAS_PRICE = 1;

    address public constant USER = address(1);

    function setUp() external {
        // With this below we are saying: "when we call fundMe,
        // we want to trigger deployFundMe"  among other setups
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_USER_BALANCE);
    }

    function testMinimumDollarIsFive() public {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    // Below test also seems to PASS when the syntax is fundMe.i_owner
    // but costs more gas, because you pull from storage
    function testOwnerIsMsgSender() public {
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testPriceFeedVersionIsAccurate() public {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function testFundFailsWithoutEnoughETH() public {
        vm.expectRevert(); // we expect a fail 'cause we send no value.
        fundMe.fund(); //here we call the fundMe.fund without value (no Eth)
    }

    function testFundUpdatesFundedDataStructure() public {
        vm.startPrank(USER);
        fundMe.fund{value: SEND_VALUE}();
        vm.stopPrank();

        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddsFunderToArrayOfFunders() public {
        vm.startPrank(USER); //create dummy user
        fundMe.fund{value: SEND_VALUE}(); // have him call the fund function with the SEND_VALUE amount.
        vm.stopPrank();
        // we call the getFunder function which takes an index(of the funders array)
        // and looks up the corresponding funder address and reurns it. That returned
        // address we "catch" in the local(function) variable called funder
        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        assert(address(fundMe).balance > 0);
        _;
    }

    function testOwnlyOwnerCanWithdraw() public funded {
        vm.expectRevert();
        fundMe.withdraw();
    }

    function testWithdrawFromASingleFunder() public funded {
        //arrange
        uint256 startingFundMeBalance = address(fundMe).balance; // the balance of the fundMe contract address
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        // vm.txGasPrice(GAS_PRICE);
        // uint256 gasStart = gasleft();
        // // Act
        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        // uint256 gasEnd = gasleft();
        // uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;

        // Assert
        uint256 endingFundMeBalance = address(fundMe).balance;
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(
            startingFundMeBalance + startingOwnerBalance,
            endingOwnerBalance // + gasUsed
        );
    }

    function testWithdrawFromMultipleFunders() public funded {
        //arrange
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            // we have to vm.prank  some dummy-funders
            // vm.deal     them some money
            // but we will use hoax which is a combination of prank and deal
            // fund the fundMe
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }
        uint256 startingFundMeBalance = address(fundMe).balance;
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        ///act
        vm.startPrank(fundMe.getOwner()); // makes sure we are calling this
        fundMe.withdraw();
        vm.stopPrank();
        /// assert
        assert(address(fundMe).balance == 0);
        assert(
            startingFundMeBalance + startingOwnerBalance ==
                fundMe.getOwner().balance
        );
    }

    // below start bigBagBoogie's tests  ////////////////////////////

    // This first test is the same as "testAddsFunderToArrayOfFunders",
    // however it uses hoax, does an extra step by sticking the address
    // of the funder from funder array in a variable before doing assert
    // and does some console logging so use -vvvv

    function testFundersGetAddedToArray() public {
        //arrange  prank a user
        hoax(address(USER), SEND_VALUE);

        //Act   user funds fundMe
        fundMe.fund{value: SEND_VALUE}();
        address firstlyAddedFunder = address(fundMe.s_funders(0));
        //assert   index 0 of the funders array now = the address of the user
        assertEq(firstlyAddedFunder, USER);
        console.log(USER, firstlyAddedFunder);
    }
}
