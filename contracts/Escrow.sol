//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Escrow {
    
    address payable public owner;

    uint256 public txid = 1;

    enum Status { PENDING, CONFIRMED, WITHDRAWN, DISPUTED, REFUNDED, RELEASED }

    struct Transaction {
        
        address sender;
        address receiver;
        uint256 amount;
        Status status;

    }

    mapping(uint256 => Transaction) public transactions;

    mapping(address => bool) public admins;

    constructor() {

        owner = payable(msg.sender);

    }

    function Deposit(address _receiver) external payable {

        require(_receiver != address(0), "Cannot escrow funds to zero address");

        transactions[txid] = Transaction(

            msg.sender,
            _receiver,
            msg.value,
            Status.PENDING

        );

        txid ++;

        //ADD EVENT FOR ESCROW CREATION
    }

    function Confirm(uint256 _id) external {

        //TRANSFORM INTO A MODIFIER?
        require(
            msg.sender == transactions[_id].sender, 
            "Transactions can only be confirmed by the sender"
        );
        require(
            transactions[_id].status == Status.PENDING,
            "Transaction needs to be pending so it can be confirmed"
        );

        transactions[_id].status = Status.CONFIRMED;

        //ADD EVENT FOR SENDER CONFIRMATION
    }

    function Withdraw(uint256 _id) external {

        require(
            msg.sender == transactions[_id].receiver, 
            "Transactions can only be withdrawn by established receiver"
        );
        require(
            transactions[_id].status == Status.CONFIRMED, 
            "Transaction need to be confirmed before being able to withdraw"
        );

        Transaction storage transaction = transactions[_id];

        transaction.status = Status.WITHDRAWN;

        (bool success, ) = transaction.receiver.call{value: transaction.amount}("");
        require(success, "Transfer failed");

        //ADD EVENT FOR WITHDRAWALS
    }

}