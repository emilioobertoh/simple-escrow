//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Escrow {
    
    address payable public owner;

    enum Status { PENDING, CONFIRMED, DISPUTED, REFUNDED, RELEASED }

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
}