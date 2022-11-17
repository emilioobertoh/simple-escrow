//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Escrow {
    
    address payable public owner;

    uint256 public txid = 1;

    enum Status { PENDING, CONFIRMED, WITHDRAWN, DISPUTED, REFUNDED, RELEASED }

    event TransactionCreated(

        address indexed sender,
        address indexed receiver,
        uint256 txid,
        uint256 amount

    );

    event TransactionConfirmed(

        address indexed sender,
        address indexed receiver,
        uint256 txid,
        uint256 amount

    );

    event TransactionWithdrawn(

        address indexed sender,
        address indexed receiver,
        uint256 txid,
        uint256 amount 

    );

    event TransactionDisputed(

        address indexed sender,
        address indexed receiver,
        uint256 txid,
        uint256 amount 

    );
    
    event TransactionRefunded(

        address indexed admin,
        address indexed sender,
        address indexed receiver,
        uint256 txid,
        uint256 amount 

    );

    event TransactionReleased(

        address indexed admin,
        address indexed sender,
        address indexed receiver,
        uint256 txid,
        uint256 amount 

    );

    event AdminAdded(

        address indexed addedAdmin

    );

    event AdminDeleted(

        address indexed addedAdmin
        
    );


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

        emit TransactionCreated(msg.sender, _receiver, txid, msg.value);
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

        emit TransactionConfirmed(msg.sender, transaction.receiver, txid, transaction.amount);
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

        emit TransactionWithdrawn(transaction.sender, transaction.receiver, txid, transaction.amount);
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

        emit TransactionDisputed(transaction.sender, transaction.receiver, txid, transaction.amount);
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

        emit TransactionRefunded(msg.sender, transaction.sender, transaction.receiver, txid, transaction.amount);
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

        emit TransactionReleased(msg.sender, transaction.sender, transaction.receiver, txid, transaction.amount);

    }

    //ADD MODIFIER FOR OWNER ONLY
    function AddAdmin(address _admin) external {

        require(!admins[_admin], "Admin already exist");

        admins[_admin] = true;

        emit AdminAdded(_admin);
    }

    //ADD MODIFIER FOR OWNER ONLY
    function DeleteAdmin(address _admin) external {
        
        require(admins[_admin], "Can delete only listed admins");

        delete admins[_admin];

        emit AdminDeleted(_admin);
    }

}