// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {PriceConverter} from "src/PriceConverter.sol";

error FUNDME__NotOwner();

contract FundMe {
    using PriceConverter for uint256;

    mapping(address => uint256) private s_addressToAmountFunded;
    address[] public s_funders;

    // Could we make this constant?  /* hint: no! We should make it immutable! */
    address public /* immutable */ i_owner;
    uint256 public constant MINIMUM_USD = 5 * 10 ** 18;
    AggregatorV3Interface private s_priceFeed;
    
    constructor(address priceFeed) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeed);
    }

    function fund() public payable {
        require(msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD, "You need to spend more ETH!");
        // require(PriceConverter.getConversionRate(msg.value) >= MINIMUM_USD, "You need to spend more ETH!");
        s_addressToAmountFunded[msg.sender] += msg.value;
        s_funders.push(msg.sender);
    }
    
    
    modifier onlyOwner {
        // require(msg.sender == owner);
        if (msg.sender != i_owner) revert FUNDME__NotOwner();
        _;
    }
    
    function withdraw() public onlyOwner {
        // loop thourgh the s_funders array
        for (uint256 funderIndex=0; funderIndex < s_funders.length; funderIndex++){
            // each time you find a funder stick it in the funder variable
            address funder = s_funders[funderIndex];
            // below we use the funder variable as a key to the key-pair
            // s_addressToAmountFunded (mapping) to set the amount that
            //corresponds to the specific funder to "0".
            s_addressToAmountFunded[funder] = 0;
            // and then back up for the next iteration of the loop
        }
        s_funders = new address[](0);
    //  There are 3 ways to transfer ether:

        // // 1 transfer
        // payable(msg.sender).transfer(address(this).balance);
        
        // // 2 send
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send failed");

        // // 3 call
        // notice the comma below after bool callSuccess. This represents
        // the data that is returned with this call-function that we don't
        // care about
        (bool callSuccess, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call failed");
    }
    // Explainer from: https://solidity-by-example.org/fallback/
    // Ether is sent to contract
    //      is msg.data empty?
    //          /   \ 
    //         yes  no
    //         /     \
    //    receive()?  fallback() 
    //     /   \ 
    //   yes   no
    //  /        \
    //receive()  fallback()

    fallback() external payable {
        fund();
    }

    receive() external payable {
        fund();
    }


////////////////////////////////////////////////
//// view and pure functions   (our getters) ///
////////////////////////////////////////////////
    function getVersion() external view returns (uint256){
        return s_priceFeed.version();
    }
     
    function getAddressToAmountFunded(address fundingAddress) external view returns (uint256){
        return s_addressToAmountFunded[fundingAddress];
    }
    function getFunder(uint256 index) external view returns (address){
        return s_funders[index];
    }

// Concepts we didn't cover yet (will cover in later sections)
// 1. Enum
// 2. Events
// 3. Try / Catch
// 4. Function Selector
// 5. abi.encode / decode
// 6. Hash with keccak256
// 7. Yul / Assembly


}