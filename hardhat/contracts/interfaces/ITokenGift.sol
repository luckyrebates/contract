//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

interface ITokenGift {
    enum Status {
        Pending,
        Open, //1 Open betting
        Close, //2 Stop betting and wait for the lottery draw
        Claimable //3 Prize has been drawn
    }
    enum Model {
        Null,
        BuyModel, //1
        SendModel //2
    }
    event TokenGiftCreated(
        uint256 indexed id,
        uint16 model,
        uint256 endTime,
        uint256 maxTickets,
        uint256 maxPrizeNum,
        uint256 ticketPirce,
        address ticketToken,
        address allowAddr,
        bool autoClaim,
        uint256 secret
    );

    event TokenGiftClosed(
        uint256 indexed id,
        uint256 endTime,
        uint256 buyTickets,
        uint256 sendTickets,
        uint256 injectTickets
    );

    event TokenGiftClaimable(
        uint256 indexed id,
        uint256 endTime,
        uint256 nonce,
        uint256 vrfRandom,
        uint256 randomResult
    );

    //ticketIndex indicates the starting number of the purchase ticket
//If ticketIndex is 23 and ticketNumbers is 1, then the prize number is 23
//If ticketIndex is 0 and ticketNumbers is 10, then the prize numbers are 0-9
    event TicketsPurchase(
        uint256 indexed id,
        address indexed sender,
        address indexed receiveAddress,
        uint256 ticketIndex,
        uint256 ticketNumbers
    );

    event TicketsGet(
        uint256 indexed id,
        address indexed sender,
        address indexed receiveAddress,
        uint256 ticketIndex,
        uint256 ticketNumbers
    );

    event TicketsInject(
        uint256 indexed id,
        address indexed sender,
        uint256 ticketNumbers
    );

    event PrizeDrawn(
        uint256 indexed id,
        address indexed winner,
        uint256 indexed index,
        uint256 amount,
        bool autoClaim
    );

    event ClaimPrize(
        uint256 indexed id,
        address indexed winner,
        uint256 totalAmount,
        bool autoClaim
    );
    /**
*@notice create the TokenGift, using the default token address and configuration. By default, it only supports buyTickets mode.
*@dev Callable by operator
*@param _endTime: endTime of the TokenGift, 0 = no limit
*@param _maxTickets: max ticket of the TokenGift, 0 = no limit
*@param _maxPrizeNum: prize num of the TokenGift, 0 means 100% winning
*@param _secret:
*/
    function createTokenGift(
        uint256 _endTime,
        uint256 _maxTickets,
        uint256 _maxPrizeNum,
        uint256 _secret
    ) external;

    //Refinedly create red envelopes, specify the tokens and prize prices of this batch of red envelopes,
    function createTokenGiftDetail(
        address _tokenAddress, //Token address
        uint16 _model, //1:为buy model;2:send model
        uint256 _ticketPirce,
        uint256 _endTime,
        uint256 _maxTickets,
        uint256 _maxPrizeNum,
        address _injectAddress, //Tokens can be donated to the red envelope prize pool when creating an event, and an approval limit is required
        uint256 _injectTicketNum, //Donation amount during initialization, 0 means no donation
        address _allowAddr, //Specify the callable address. If the setting is not 0x0, only this address is allowed to be called. Otherwise, any address is allowed to be called.
        uint256 _secret,
        bool _autoClaim //Whether to automatically claim it, if it is false, the winning user needs to claim the prize by themselves.
    ) external;

    //Donate the amount of assets to the prize pool, do not participate in the lottery, can be called from any address, and require approval authorization
    function injectTickets(uint256 _id, uint256 _ticketNumbers) external;

    //In send tickets mode, it can be called by the send allow addr address to specify the amount of prizes to be claimed.
    function sendTickets(
        uint256 _id,
        address _receiveAddress,
        uint256 _ticketNumbers
    ) external;

    //Can be called by any address in buy tickets mode, requires approve quota
    function buyTickets(
        uint256 _id,
        address _receiveAddress,
        uint256 _ticketNumbers
    ) external;

    //End betting. After calling, the red envelope will no longer accept inject tickets/get tickets/buy tickets.
    function endTokenGift(uint256 _id) external;

    //Lottery draw, if auto claim is true, prizes will be automatically distributed to winning users
    function drawPrize(uint256 _id, uint256 _nonce) external;

    //After the lottery is drawn, if auto claim is false, the winning user needs to call this interface to claim the prize manually.
    function claimPrize(uint256 _id) external;

    //Query the specified red envelope details
    function viewTokenGiftStatus(uint256 _id) external view returns (Status);
    function viewTokenGiftModel(uint256 _id) external view returns (Model);
    function viewTokenGiftTicketToken(
        uint256 _id
    ) external view returns (address);
    function viewTokenGiftTicketPrice(
        uint256 _id
    ) external view returns (uint256);

    //Query the latest red envelope id
    function viewCurrentTokenGiftId() external view returns (uint256);

    //Query the winning amount that the specified user can claim
    function viewTokenGiftClaimPrize(
        uint256 _id,
        address _user
    ) external view returns (uint256);
}
