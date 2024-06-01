//SPDX-License-Identifier: MIT
//Compatible with OpenZeppelin Contracts ^4.0.0
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../interfaces/ITokenGift.sol";
import "../interfaces/ITaskControlWithToken.sol";
import "../interfaces/ItaskCallee.sol";

contract TaskControlWithToken is ITaskControlWithToken,ERC20,ReentrancyGuard, ERC20Burnable, Ownable {
    using SafeERC20 for IERC20;
    ITokenGift tokenGift;
    bool public allowBuyTicket;
    bool public allowSendTicket;

    mapping(address => uint256) public taskMap;     //Record tasks and weights

    error NotAllowModel(uint256 id, ITokenGift.Model model);

    event TaskAdd(address taskAddr,uint256 weight);

    constructor(address _tokenGiftAddr,bool _allowBuyTicket,bool _allowSendTicket)
        ERC20("lotteryTicket", "Ticket")
        Ownable()
    {
        //_mint(msg.sender, 10000 *10 **decimals());
        tokenGift = ITokenGift(_tokenGiftAddr);
        allowBuyTicket = _allowBuyTicket;
        allowSendTicket = _allowSendTicket;
        
    }

    /*
function decimals() public view override virtual returns (uint8) {
return 6;
}*/
//Set the task and weight. If the weight is 0, it is equivalent to deleting the task.
    function setTask(address _taskAddr,uint256 _weight)external onlyOwner{
        taskMap[_taskAddr] = _weight;
        emit TaskAdd(_taskAddr, _weight);
    }
    function getTask(address _taskAddr)external view  returns(uint256) {
        return taskMap[_taskAddr];
    }
    function updateTokenGift(address _tokenGiftAddr,bool _allowBuyTicket,bool _allowSendTicket)external onlyOwner{
        tokenGift = ITokenGift(_tokenGiftAddr);
        allowBuyTicket = _allowBuyTicket;
        allowSendTicket = _allowSendTicket;
    }
    
    function _mintToken(address _taskAddr,address _receiveAddress,bytes calldata _data)internal returns(uint256){
        require(taskMap[_taskAddr] != 0,"no set as task");
        uint256 value = ItaskCallee(_taskAddr).taskCall{value: msg.value}(address(msg.sender),_data);
    
        //The actual number of minted tokens is the run task return value *weight
        uint256 amount = value * taskMap[_taskAddr];
        _mint(_receiveAddress, amount);

        emit TokenMint(address(msg.sender),_taskAddr,_receiveAddress,amount);

        return amount;

    }

    function mintToken(address _taskAddr,address _receiveAddress,bytes calldata _data) external virtual override payable nonReentrant {
        _mintToken(_taskAddr,_receiveAddress,_data);
    }

    function _getTicket(uint256 _id,address _receiveAddress,uint256 _ticketNumbers)internal returns(bool){
        bool buy = true;

        if (tokenGift.viewTokenGiftModel(_id) == ITokenGift.Model.BuyModel){      
            if (allowBuyTicket != true){
                revert NotAllowModel(_id, tokenGift.viewTokenGiftModel(_id));
            }
            uint256 approveAmount = tokenGift.viewTokenGiftTicketPrice(_id) * _ticketNumbers;
            IERC20(tokenGift.viewTokenGiftTicketToken(_id)).approve(address(tokenGift),approveAmount);       
            tokenGift.buyTickets(_id,_receiveAddress,_ticketNumbers);
        }else{
            require(allowSendTicket == true, "send ticket no allow");                
            tokenGift.sendTickets(_id,_receiveAddress,_ticketNumbers);
            buy = false;
        }
        return buy;
    }

    function getTicket(uint256 _id,address _receiveAddress,uint256 _ticketNumbers)external virtual override {
        uint256 amount = _ticketNumbers * 10 ** decimals();
        burn(amount);
        bool buy = _getTicket(_id,_receiveAddress,_ticketNumbers);

        emit TicketGet(_id,address(msg.sender),_receiveAddress,amount,_ticketNumbers,buy);
    }
    function getTicketFrom(uint256 _id,address _fromAddress,address _receiveAddress,uint256 _ticketNumbers)external virtual override {
        uint256 amount = _ticketNumbers * 10 ** decimals();
        burnFrom(_fromAddress,amount);
        bool buy = _getTicket(_id,_receiveAddress,_ticketNumbers);

        emit TicketGet(_id,_fromAddress,_receiveAddress,amount,_ticketNumbers,buy);
    }

    //Withdraw third-party tokens
    function withdraw(address _token,address _to,uint256 _value)external virtual onlyOwner{
        IERC20(_token).transfer(_to,_value);
    }
}