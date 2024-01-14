// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract SPYDR {
    string public name = "SPYDR";
    string public symbol = "SPYDR";
    uint8 public decimals = 18;
    uint256 public totalSupply;
    uint256 public currentPrice; // Added to track the current price.
    address public owner; // Added to track the contract owner.
    
    uint256 public reserveBalance; // Ether in the reserve
    uint256 public scalingFactor; // Scaling factor for the bonding curve

    mapping(address => uint256) public balanceOf;

    AggregatorV3Interface internal priceFeed = AggregatorV3Interface(0xF4E1B57FB228879D057ac5AE33973e8C53e4A0e0);

    // Added modifier to restrict certain functions to the contract owner.
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    constructor() {
        totalSupply = 1000000 * (10 ** uint256(decimals));
        balanceOf[msg.sender] = totalSupply;
        owner = msg.sender; // Set the contract owner.
        
        // Set the initial price to 1 USD (in the token's smallest unit).
        uint256 initialPrice = 1 * (10 ** uint256(decimals));
        currentPrice = initialPrice; // Set the current price.

        reserveBalance = 10 ether; // Initial Ether in the reserve
        scalingFactor = 1000; // Initial scaling factor
    }

    function getISharesPrice() internal view returns (uint256) {
        (, int256 price, , ,) = priceFeed.latestRoundData();
        return uint256(price);
    }

    function getMyCoinPrice() public view returns (uint256) {
        return currentPrice;
    }

    function buyMyCoins(uint256 amount) public payable {
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

        // Note: Ensure that the contract has enough reserveBalance to fulfill the request.
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

    // Function to update the price (could be called by an authorized party).
    function updatePrice(uint256 newPrice) public onlyOwner {
        currentPrice = newPrice;
    }

    // Fallback function to receive Ether (if applicable).
    receive() external payable {}

    // Additional function to withdraw funds (if needed).
    function withdrawFunds() public onlyOwner {
        payable(owner).transfer(address(this).balance);
    }
}
