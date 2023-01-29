//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/Pausable.sol";

contract Escrow is Pausable {
    
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

        address indexed deletedAdmin
        
    );

    modifier onlyAuthorized() {
        
        if(msg.sender != owner) {

            require(admins[msg.sender], "Unauthorized address" );
            _;

        } else {

            _;

        }

    }

    modifier onlyOwner() {

        require(msg.sender == owner, "Unauthorized address");
        _;

    }

    constructor() {

        owner = payable(msg.sender);

    }

    function deposit(address _receiver) external payable whenNotPaused {

        require(_receiver != address(0), "Cannot escrow funds to zero address");

        transactions[txid] = Transaction(

            msg.sender,
            _receiver,
            msg.value,
            Status.PENDING

        );

        emit TransactionCreated(

            msg.sender, 
            _receiver, 
            txid, 
            msg.value

        );

        txid ++;

    }

    function confirm(uint256 _id) external whenNotPaused {

        Transaction storage transaction = transactions[_id];

        /* ADD A WAY OF SHOWING WHEN THE TRANSACTION IS BEING REVERTED
        DUE TO NON EXISTING ID */
        
        require(
            msg.sender == transaction.sender, 
            "Transactions can only be confirmed by the sender"
        );
        require(
            transaction.status == Status.PENDING,
            "Transaction needs to be pending so it can be confirmed"
        );

        transaction.status = Status.CONFIRMED;

        emit TransactionConfirmed(

            msg.sender, 
            transaction.receiver, 
            txid, 
            transaction.amount

        );

    }

    function withdraw(uint256 _id) external payable whenNotPaused {

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

        emit TransactionWithdrawn(

            transaction.sender, 
            transaction.receiver, 
            _id, 
            transaction.amount

        );
    }

    function dispute(uint256 _id) external whenNotPaused {
        
        Transaction storage transaction = transactions[_id];

        if(msg.sender != transaction.sender) {

            require(
                msg.sender == transaction.receiver,
                "Only sender or receiver can dispute a transaction"
            );
            require(
                transaction.status == Status.PENDING,
                "Confirmed or withdrawn transactions cannot be disputed"
            );

            transaction.status = Status.DISPUTED;

            emit TransactionDisputed(

                transaction.sender, 
                transaction.receiver, 
                txid, transaction.amount

            );

        } else {

            require(
                transaction.status == Status.PENDING,
                "Confirmed or completed transactions cannot be disputed"
            );

            transaction.status = Status.DISPUTED;

            emit TransactionDisputed(

                transaction.sender, 
                transaction.receiver, 
                txid, transaction.amount

            );

        }

    }

    function refund(uint256 _id) external payable onlyAuthorized whenNotPaused {
        
        Transaction storage transaction = transactions[_id];

        require(
            transaction.status == Status.DISPUTED,
            "Only disputed transactions can be refunded by an admin"    
        );

        transaction.status = Status.REFUNDED;

        (bool success, ) = transaction.sender.call{value: transaction.amount}("");
        require(success, "Transaction failed");

        emit TransactionRefunded(

            msg.sender, 
            transaction.sender, 
            transaction.receiver, 
            txid, 
            transaction.amount

        );

    }

    function release(uint256 _id) external payable onlyAuthorized whenNotPaused {

        Transaction storage transaction = transactions[_id];

        require(
            transaction.status == Status.DISPUTED,
            "Only disputed transactions can be released by an admin"    
        );

        transaction.status = Status.RELEASED;

        (bool success, ) = transaction.receiver.call{value: transaction.amount}("");
        require(success, "Transaction failed");

        emit TransactionReleased(
            
            msg.sender, 
            transaction.sender, 
            transaction.receiver, 
            txid, 
            transaction.amount

        );

    }

    function addAdmin(address _admin) external onlyOwner whenNotPaused {

        require(!admins[_admin], "Admin already exist");

        admins[_admin] = true;

        emit AdminAdded(
            
            _admin
            
        );
    }

    function deleteAdmin(address _admin) external onlyOwner whenNotPaused{
        
        require(admins[_admin], "Can delete only listed admins");

        delete admins[_admin];

        emit AdminDeleted(
            
            _admin
            
        );
        
    }

    function pause() public onlyOwner {

        _pause();

    }

    function unpause() public onlyOwner {

        _unpause();

    }

}