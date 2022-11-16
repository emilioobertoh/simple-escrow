//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Escrow {
    
    address payable public owner;

    uint256 public txid = 1;

    event TransactionCreated(

        address indexed sender,
        address indexed receiver,
        uint256 txid

    );

    event TransactionConfirmed(

        address indexed sender,
        address indexed receiver,
        uint256 txid

    );

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

        emit TransactionCreated(msg.sender, _receiver, txid);
    }

    function Confirm(uint256 _id) external {

        Transaction storage transaction = transactions[_id];
        
        //TRANSFORM INTO A MODIFIER?
        require(
            msg.sender == transaction.sender, 
            "Transactions can only be confirmed by the sender"
        );
        require(
            transaction.status == Status.PENDING,
            "Transaction needs to be pending so it can be confirmed"
        );

        transaction.status = Status.CONFIRMED;

        emit TransactionConfirmed(msg.sender, transaction.receiver, txid);
    }

    function Withdraw(uint256 _id) external payable {

        Transaction storage transaction = transactions[_id];

        require(
            msg.sender == transaction.receiver, 
            "Transactions can only be withdrawn by established receiver"
        );
        require(
            transaction.status == Status.CONFIRMED, 
            "Transaction need to be confirmed before being able to withdraw"
        );

        transaction.status = Status.WITHDRAWN;

        (bool success, ) = transaction.receiver.call{value: transaction.amount}("");
        require(success, "Transfer failed");

        //ADD EVENT FOR WITHDRAWALS
    }

    function Dispute(uint256 _id) external {
        
        Transaction storage transaction = transactions[_id];

        if(msg.sender != transaction.sender) {

            require(
                msg.sender == transaction.receiver,
                "Only sender or receiver can dispute a transaction"
            );

        } else {

            require(
                transaction.status == Status.PENDING,
                "Confirmed or completed transactions cannot be disputed"
            );

            transaction.status = Status.DISPUTED;

        }

        //ADD EVENT FOR DISPUTED TRANSACTION
    }

    //ADD A ONLY ADMIN AND OWNER MODIFIER
    function Refund(uint256 _id) external payable {
        
        Transaction storage transaction = transactions[_id];

        require(
            transaction.status == Status.DISPUTED,
            "Only disputed transactions can be refunded by an admin"    
        );

        transaction.status = Status.REFUNDED;

        (bool success, ) = transaction.sender.call{value: transaction.amount}("");
        require(success, "Transaction failed");

        //ADD EVENT FOR REFUNDED TRANSACTIONS
    }

    //ADD ONLY ADMIN AND OWNER MODIFIER
    function Release(uint256 _id) external payable {

        Transaction storage transaction = transactions[_id];

        require(
            transaction.status == Status.DISPUTED,
            "Only disputed transactions can be released by an admin"    
        );

        transaction.status = Status.RELEASED;

        (bool success, ) = transaction.receiver.call{value: transaction.amount}("");
        require(success, "Transaction failed");

        //ADD EVENT FOR REFUNDED TRANSACTIONS

    }

    //ADD MODIFIER FOR OWNER ONLY
    function AddAdmin(address _admin) external {

        require(!admins[_admin], "Admin already exist");

        admins[_admin] = true;

        //ADD EVENT FOR ADMIN LISTING
    }

    //ADD MODIFIER FOR OWNER ONLY
    function DeleteAdmin(address _admin) external {
        
        require(admins[_admin], "Can delete only listed admins");

        delete admins[_admin];

        //ADD EVENT FOR ADMIN DELETION
    }

}