    // SPDX-License-Identifier: MIT
    // Compatible with OpenZeppelin Contracts ^5.0.0
    pragma solidity ^0.8.19;

    interface ITaskControlDirect  {
        event TicketGet(uint256 id,address taskAddr, address fromAddress,address receiveAddress,uint256 ticketNumbers,bool buy);
        
        //Perform the task and receive the specified red envelope for betting
        function getTicket(uint256 _id,address _taskAddr,address _receiveAddress,bytes calldata _data)external payable;
    }