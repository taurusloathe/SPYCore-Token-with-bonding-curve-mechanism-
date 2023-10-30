// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract MyCryptocurrency {
    string public name = "MyCryptocurrency";
    string public symbol = "MYC";
    uint8 public decimals = 18;
    uint256 public totalSupply;
    uint256 public currentPrice; // Added to track the current price.

    mapping(address => uint256) public balanceOf;

    AggregatorV3Interface internal priceFeed = AggregatorV3Interface(0xF4E1B57FB228879D057ac5AE33973e8C53e4A0e0);

    constructor() {
        totalSupply = 1000000 * (10 ** uint256(decimals));
        balanceOf[msg.sender] = totalSupply;
        
        // Set the initial price to 1 USD (in the token's smallest unit).
        uint256 initialPrice = 1 * (10 ** uint256(decimals));
        currentPrice = initialPrice; // Set the current price.
    }

    function getISharesPrice() internal view returns (uint256) {
        (, int256 price, , ,) = priceFeed.latestRoundData();
        return uint256(price);
    }

    function getMyCoinPrice() public view returns (uint256) {
        return currentPrice;
    }

    function buyMyCoins(uint256 amount) public payable {
        uint256 cost = (currentPrice * amount) / (10 ** uint256(decimals));
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        require(msg.value == cost, "Incorrect amount sent");
        balanceOf[msg.sender] -= amount;
        balanceOf[address(this)] += amount;
    }

    function sellMyCoins(uint256 amount) public {
        uint256 revenue = (currentPrice * amount) / (10 ** uint256(decimals));
        require(balanceOf[address(this)] >= amount, "Insufficient balance");
        balanceOf[address(this)] -= amount;
        balanceOf[msg.sender] += amount;
        payable(msg.sender).transfer(revenue);
    }

    // Function to update the price (could be called by an authorized party).
    function updatePrice(uint256 newPrice) public {
        currentPrice = newPrice;
    }
}
