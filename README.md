// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract MyCryptocurrency { 
    string public name = "MyCryptocurrency"; 
    string public symbol = "MYC"; 
    uint8 public decimals = 18; 
    uint256 public totalSupply; 
    uint256 public currentPrice; 
    address public owner; 

    uint256 public reserveBalance; 
    uint256 public scalingFactor; 

    mapping(address => uint256) public balanceOf;

    AggregatorV3Interface internal priceFeed;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    constructor() {
        totalSupply = 1000000 * (10 ** uint256(decimals));
        balanceOf[msg.sender] = totalSupply;
        owner = msg.sender; 
        
        uint256 initialPrice = 1 * (10 ** uint256(decimals));
        currentPrice = initialPrice; 

        reserveBalance = 10 ether; 
        scalingFactor = 1000; 

        // Initialize the price feed contract
        priceFeed = AggregatorV3Interface(0xF4E1B57FB228879D057ac5AE33973e8C53e4A0e0);
    }

    function getISharesPrice() internal view returns (uint256) {
        (, int256 price, , ,) = priceFeed.latestRoundData();
        return uint256(price);
    }

    function getMyCoinPrice() public view returns (uint256) {
        return currentPrice;
    }

    function buyMyCoins() public payable {
        uint256 tokensToMint = calculateTokensToMint(msg.value);
        require(tokensToMint <= totalSupply, "Exceeds total supply");

        totalSupply += tokensToMint;
        balanceOf[msg.sender] += tokensToMint;
        reserveBalance += msg.value;
    }

    function sellMyCoins(uint256 amount) public {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");

        uint256 ethToReturn = calculateEtherToReturn(amount);
        totalSupply -= amount;
        balanceOf[msg.sender] -= amount;

        require(ethToReturn <= reserveBalance, "Insufficient reserve");

        reserveBalance -= ethToReturn;
        payable(msg.sender).transfer(ethToReturn);
    }

    function calculateTokensToMint(uint256 eth) internal view returns (uint256) {
        return (scalingFactor * eth * totalSupply) / (reserveBalance + (eth * scalingFactor));
    }

    function calculateEtherToReturn(uint256 tokens) internal view returns (uint256) {
        return ((reserveBalance * tokens) / totalSupply) / scalingFactor;
    }

    function updatePrice(uint256 newPrice) public onlyOwner {
        currentPrice = newPrice;
    }

    receive() external payable {}

    function withdrawFunds() public onlyOwner {
        payable(owner).transfer(address(this).balance);
    }
}
