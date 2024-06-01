    //SPDX-License-Identifier: MIT
//Compatible with OpenZeppelin Contracts ^5.0.0
    pragma solidity ^0.8.19;

    interface ITaskControlWithToken  {
        event TokenMint(address sender,address taskAddr,address receiveAddress,uint256 amount);
        event TicketGet(uint256 id,address fromAddress,address receiveAddress,uint256 amount,uint256 ticketNumbers,bool buy);
        
        //Execute the task addr contract task and issue task tokens
        function mintToken(address _taskAddr,address _receiveAddress,bytes calldata _data) external payable;
        //Spend your own task tokens and participate in the lottery
        function getTicket(uint256 _id,address _receiveAddress,uint256 _ticketNumbers)  external;
        //Spend third-party authorized task tokens and participate in the lottery
        function getTicketFrom(uint256 _id,address _fromAddress,address _receiveAddress,uint256 _ticketNumbers)  external;
    }