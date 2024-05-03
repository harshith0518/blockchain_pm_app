// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MutualFund {
    struct Investor {
        uint256 shares;
        uint256 balance;
    }

    mapping(address => Investor) public investors;
    mapping(address => bool) public managers;

    string public fundName;
    uint256 public totalShares;
    uint256 public sharePrice;
    address public owner;

    event SharesPurchased(address indexed buyer, uint256 shares);
    event SharesSold(address indexed seller, uint256 shares);

    constructor(string memory _fundName, uint256 _initialShares, uint256 _sharePrice) {
        fundName = _fundName;
        totalShares = _initialShares;
        sharePrice = _sharePrice;
        owner = msg.sender;
        managers[msg.sender] = true;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier onlyManager() {
        require(managers[msg.sender], "Only manager can call this function");
        _;
    }

    function purchaseShares(uint256 _numShares) external payable {
        require(msg.value == _numShares * sharePrice, "Incorrect amount sent");

        investors[msg.sender].shares += _numShares;
        investors[msg.sender].balance += msg.value;
        totalShares += _numShares;

        emit SharesPurchased(msg.sender, _numShares);
    }

    function sellShares(uint256 _numShares) external {
        require(investors[msg.sender].shares >= _numShares, "Insufficient shares");

        uint256 saleAmount = _numShares * sharePrice;
        require(address(this).balance >= saleAmount, "Insufficient contract balance");

        investors[msg.sender].shares -= _numShares;
        investors[msg.sender].balance -= saleAmount;
        totalShares -= _numShares;

        payable(msg.sender).transfer(saleAmount);

        emit SharesSold(msg.sender, _numShares);
    }

    function withdrawFunds(uint256 _amount) external onlyOwner {
        require(address(this).balance >= _amount, "Insufficient contract balance");

        payable(owner).transfer(_amount);
    }

    function addManager(address _manager) external onlyOwner {
        managers[_manager] = true;
    }

    function removeManager(address _manager) external onlyOwner {
        require(_manager != owner, "Cannot remove owner as manager");
        delete managers[_manager];
    }

    receive() external payable {}
}
