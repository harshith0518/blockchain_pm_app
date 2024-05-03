// SPDX-License-Identifier: MIT

pragma solidity ^0.8.25;

   contract BankingSystem {
    address[] public admins;
    mapping(address => Customer) public customers;
    
    struct Customer {
        string name;
        uint balance;
        uint loanAmount;
        uint loanDeadline;
        bool hasLoan;
    }

    modifier onlyAdmin() {
        bool isAdmin = false;
        for (uint i = 0; i < admins.length; i++) {
            if (admins[i] == msg.sender) {
                isAdmin = true;
                break;
            }
        }
        require(isAdmin, "Only admin can perform this action");
        _;
    }

    event NewCustomerRegistered(address indexed customerAddress, string name);
    event Deposit(address indexed customerAddress, uint amount);
    event Withdrawal(address indexed customerAddress, uint amount);
    event LoanApplied(address indexed customerAddress, uint amount, uint deadline);
    event LoanPaid(address indexed customerAddress, uint amount);
    event PenaltyApplied(address indexed customerAddress, uint penaltyAmount);

    constructor() {
        admins.push(msg.sender);
    }
    
    function registerCustomer(address _customerAddress, string memory _name) external onlyAdmin {
        require(bytes(customers[_customerAddress].name).length == 0, "Customer already registered");
        customers[_customerAddress].name = _name;
        emit NewCustomerRegistered(_customerAddress, _name);
    }
    
    function deposit() external payable {
        require(bytes(customers[msg.sender].name).length > 0, "Customer not registered");
        customers[msg.sender].balance += msg.value;
        emit Deposit(msg.sender, msg.value);
    }
    
    function withdraw(uint _amount) external {
        require(bytes(customers[msg.sender].name).length > 0, "Customer not registered");
        require(customers[msg.sender].balance >= _amount, "Insufficient balance");
        customers[msg.sender].balance -= _amount;
        payable(msg.sender).transfer(_amount);
        emit Withdrawal(msg.sender, _amount);
    }
    
    function applyLoan(uint _loanAmount, uint _loanDeadline) external {
        require(bytes(customers[msg.sender].name).length > 0, "Customer not registered");
        require(!customers[msg.sender].hasLoan, "Loan already applied");
        customers[msg.sender].loanAmount = _loanAmount;
        customers[msg.sender].loanDeadline = _loanDeadline;
        customers[msg.sender].hasLoan = true;
        emit LoanApplied(msg.sender, _loanAmount, _loanDeadline);
    }
    
    function payLoan() external payable {
        require(bytes(customers[msg.sender].name).length > 0, "Customer not registered");
        require(customers[msg.sender].hasLoan, "No loan to pay");
        require(msg.value >= customers[msg.sender].loanAmount, "Insufficient amount to pay loan");
        customers[msg.sender].hasLoan = false;
        uint remainingAmount = msg.value - customers[msg.sender].loanAmount;
        if (remainingAmount > 0) {
            customers[msg.sender].balance += remainingAmount;
        }
        emit LoanPaid(msg.sender, customers[msg.sender].loanAmount);
    }
    
    function checkLoanStatus(address _customerAddress) external view returns (bool) {
        require(bytes(customers[_customerAddress].name).length > 0, "Customer not registered");
        return customers[_customerAddress].hasLoan;
    }
    
    function applyPenalty(address _customerAddress, uint _penaltyAmount) external onlyAdmin {
        require(customers[_customerAddress].hasLoan, "No loan to penalize");
        require(block.timestamp > customers[_customerAddress].loanDeadline, "Loan not yet due for penalty");
        require(customers[_customerAddress].balance >= _penaltyAmount, "Insufficient balance for penalty");
        customers[_customerAddress].balance -= _penaltyAmount;
        emit PenaltyApplied(_customerAddress, _penaltyAmount);
    }

    function addAdmin(address _adminAddress) external onlyAdmin {
        admins.push(_adminAddress);
    }

    function removeAdmin(address _adminAddress) external onlyAdmin {
        for (uint i = 0; i < admins.length; i++) {
            if (admins[i] == _adminAddress) {
                delete admins[i];
                break;
            }
        }
    }
}
