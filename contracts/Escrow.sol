//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Escrow {
    
    address payable public owner;

    uint256 public txid = 1;

    enum Status { PENDING, CONFIRMED, WITHDREW, DISPUTED, REFUNDED, RELEASED }

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

        //TRANSFORM INTO A MODIFIER
        require(msg.sender == transactions[_id].sender, "Transactions can only be confirmed by the sender");

        transactions[_id].status = Status.CONFIRMED;

        //ADD EVENT FOR SENDER CONFIRMATION
    }

}