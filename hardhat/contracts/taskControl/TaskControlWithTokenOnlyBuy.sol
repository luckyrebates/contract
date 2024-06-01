//SPDX-License-Identifier: MIT
//Compatible with OpenZeppelin Contracts ^4.0.0
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/ITokenGift.sol";

import "./TaskControlWithToken.sol";

contract TaskControlWithTokenOnlyBuy is TaskControlWithToken {
    using SafeERC20 for IERC20;
    address public ticketToken;
    uint256 public ticketPirce;
    address public reserveAddr;

    constructor(
        address _tokenGiftAddr,
        address _ticketToken,
        address _reserveAddr,
        uint256 _ticketPirce
    ) TaskControlWithToken(_tokenGiftAddr, true, false) {
        ticketToken = _ticketToken;
        ticketPirce = _ticketPirce;
        reserveAddr = _reserveAddr;
    }

    function mintToken(
        address _taskAddr,
        address _receiveAddress,
        bytes calldata _data
    ) external payable virtual override nonReentrant {
        uint256 amount = _mintToken(_taskAddr, _receiveAddress, _data);

        //Need to transfer the corresponding value of the red envelope token deposit
        uint256 ticketAmount = (amount * ticketPirce) / (10 ** decimals());
        IERC20(ticketToken).safeTransferFrom(
            reserveAddr,
            address(this),
            ticketAmount
        );
    }

    function _buyTicket(
        uint256 _id,
        address _receiveAddress,
        uint256 _ticketNumbers
    ) internal {
        require(
            tokenGift.viewTokenGiftTicketToken(_id) == ticketToken,
            "ticketToken err.no suport tokenGift token"
        );
        require(
            tokenGift.viewTokenGiftTicketPrice(_id) == ticketPirce,
            "ticketPirce err.no suport tokenGift token"
        );
        require(
            tokenGift.viewTokenGiftModel(_id) == ITokenGift.Model.BuyModel,
            "only buy model"
        );

        uint256 approveAmount = ticketPirce * _ticketNumbers;
        IERC20(ticketToken).approve(address(tokenGift), approveAmount);
        tokenGift.buyTickets(_id, _receiveAddress, _ticketNumbers);
    }

    function getTicket(
        uint256 _id,
        address _receiveAddress,
        uint256 _ticketNumbers
    ) external virtual override {
        uint256 amount = _ticketNumbers * 10 ** decimals();
        burn(amount);
        _buyTicket(_id, _receiveAddress, _ticketNumbers);
        emit TicketGet(
            _id,
            address(msg.sender),
            _receiveAddress,
            amount,
            _ticketNumbers,
            true
        );
    }

    function getTicketFrom(
        uint256 _id,
        address _fromAddress,
        address _receiveAddress,
        uint256 _ticketNumbers
    ) external virtual override {
        uint256 amount = _ticketNumbers * 10 ** decimals();
        burnFrom(_fromAddress, amount);
        _buyTicket(_id, _receiveAddress, _ticketNumbers);
        emit TicketGet(
            _id,
            _fromAddress,
            _receiveAddress,
            amount,
            _ticketNumbers,
            false
        );
    }

    //Do not allow withdrawal of margin tokens
    function withdraw(
        address _token,
        address _to,
        uint256 _value
    ) external virtual override onlyOwner {
        //ier c20( token).transfer( to, value);
    }
}
