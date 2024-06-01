//SPDX-License-Identifier: BUSL-1.1
//Compatible with OpenZeppelin Contracts ^4.0.0
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/ITokenGift.sol";
import "./interfaces/IRandom.sol";

//import "hardhat/console.sol";

contract LuckyTokenGift is ITokenGift,ReentrancyGuard, Ownable{
    using SafeERC20 for IERC20;

    address public g_defaultTicketToken;
    uint256 public g_defaultTicketPirce;
    bool public g_defaultAutoClaim;
    
    uint256 public currentId;
    
    mapping(address => bool) public operatorAddressMap;

    
    struct TokenGift{
        address ticketToken;
        Status status;
        Model model;
        uint256 endTime;
        uint256 maxTickets;
        uint256 maxPrizeNum;    //Maximum winning number
        uint256 buyTickets;    //The number of bets purchased by the user
        uint256 sendTickets;     //User gets the number of bets
        uint256 injectTickets;  //Number of donations
        uint256 userAddrNum;
        uint256 userTxNum;
        uint256 injectAddrNum;
        uint256 ticketPirce;
        address allowAddr;  //Specify the callable address. If the setting is not 0x0, only this address is allowed to be called. Otherwise, any address is allowed to be called.
        uint256 secret;
        bool autoClaim; 
    }

    struct Ticket{
        uint256 totalNumbers;
        address receiveAddress;
        bool buy;
    }

    mapping(uint256 => TokenGift) private tokenGiftIdMap;
    mapping(uint256 => mapping(uint256 => Ticket)) private ticketMap;
    mapping(uint256 => mapping(uint256 => bool)) private prizedTicketIndex;
  
    mapping(uint256 => mapping(address => uint256)) private userAddrTicketNumMap;
    mapping(uint256 => mapping(uint256 => address)) private userAddrIndex;
    mapping(uint256 => mapping(address => uint256)) private amount2claimedMap;

    mapping(uint256 => mapping(uint256 => address)) private injectAddrIndex;
    mapping(uint256 => mapping(address => uint256)) private injectTicketMap;


    //chainlink vrf
    IRandomGenerator randomGenerator;

    /*
modifier notContract() {
require(!_isContract(msg.sender), "Contract not allowed");
require(msg.sender == tx.origin, "Proxy contract not allowed");
_;
}*/

    modifier onlyOperator() {
        require(operatorAddressMap[msg.sender] == true, "Not operator");
        _;
    }
    modifier onlyRandomGenerator() {
        require(msg.sender == address(randomGenerator), "Not operator");
        _;
    }
    modifier allowAddress(uint256 _id) {
        if (tokenGiftIdMap[_id].allowAddr != address(0)){
            require(msg.sender == tokenGiftIdMap[_id].allowAddr, "Not allow address");
        }
        _;
    }


    event OperatorAddress(address operatorAddress,bool opt);
    event DefaultAutoClaimChange(bool defaultAutoClaim);
    event DefaultTokenChange(address defaultTicketToken,uint256 defaultTicketPirce);

    constructor(address _defaultTicketToken,uint256 _defaultTicketPirce,address _randomGenerator)
    Ownable(){
        operatorAddressMap[msg.sender] = true;
        g_defaultAutoClaim = true;
        g_defaultTicketToken = _defaultTicketToken;
        g_defaultTicketPirce = _defaultTicketPirce;

        randomGenerator = IRandomGenerator(_randomGenerator);

        emit OperatorAddress(msg.sender,true);
        emit DefaultAutoClaimChange(g_defaultAutoClaim);
        emit DefaultTokenChange(g_defaultTicketToken,g_defaultTicketPirce);
    }

    function setOperatorAddress(
        address _operatorAddress,
        bool _opt
    )external onlyOwner{
        require(_operatorAddress != address(0), "Cannot be zero address");
        operatorAddressMap[_operatorAddress] = _opt;

        emit OperatorAddress(_operatorAddress,_opt);
    }

    function setDefaultAutoClaim(bool _defaultAutoClaim) external onlyOperator{
        g_defaultAutoClaim = _defaultAutoClaim;
        emit DefaultAutoClaimChange(_defaultAutoClaim);
    }

     function setTicketToken(address _defaultTicketToken,uint256 _defaultTicketPirce) external onlyOperator{
        g_defaultTicketToken = _defaultTicketToken;
        g_defaultTicketPirce = _defaultTicketPirce;
        emit DefaultTokenChange(_defaultTicketToken,_defaultTicketPirce);
    }

    
    function _createTokenGift(address _tokenAddress,
        uint16 _model,
        uint256 _ticketPirce,
        uint256 _endTime,
        uint256 _maxTickets,
        uint256 _maxPrizeNum,
        address _allowAddr,
        uint256 _secret,
        bool _autoClaim
        )internal {
        currentId++;
        TokenGift storage tokenGift = tokenGiftIdMap[currentId];
        tokenGift.ticketToken = _tokenAddress;
        tokenGift.model = Model(_model);
        tokenGift.status = Status.Open;
        tokenGift.endTime = _endTime;
        tokenGift.maxTickets = _maxTickets;
        tokenGift.maxPrizeNum = _maxPrizeNum;
        tokenGift.ticketPirce = _ticketPirce;
        tokenGift.secret = _secret;
        tokenGift.autoClaim = _autoClaim;
        tokenGift.allowAddr = _allowAddr;

        _genTokenGiftCreatedEvent(currentId);
    }
    function _genTokenGiftCreatedEvent(uint256 _id)internal{
        emit TokenGiftCreated(_id,uint16(tokenGiftIdMap[_id].model),tokenGiftIdMap[_id].endTime,tokenGiftIdMap[_id].maxTickets,tokenGiftIdMap[_id].maxPrizeNum,tokenGiftIdMap[_id].ticketPirce,tokenGiftIdMap[_id].ticketToken,tokenGiftIdMap[_id].allowAddr,tokenGiftIdMap[_id].autoClaim,tokenGiftIdMap[_id].secret);
    }

    
    function createTokenGift(
        uint256 _endTime,
        uint256 _maxTickets,
        uint256 _maxPrizeNum,
        uint256 _secret
    )external onlyOperator nonReentrant{
        _createTokenGift(g_defaultTicketToken,uint16(Model.BuyModel),g_defaultTicketPirce,_endTime,_maxTickets,
            _maxPrizeNum,address(0),_secret,g_defaultAutoClaim);
    }

    /**
*@notice create the TokenGift
*@dev Callable by operator
*@param _endTime: endTime of the TokenGift
*@param _maxTickets: max ticket of the TokenGift
*@param _secret:
*/
    function createTokenGiftDetail(
        address _tokenAddress,
        uint16 _model,
        uint256 _ticketPirce,
        uint256 _endTime,
        uint256 _maxTickets,
        uint256 _maxPrizeNum,
        address _injectAddress,
        uint256 _injectTicketNum,
        address _allowAddr,
        uint256 _secret,
        bool _autoClaim
    )external onlyOperator nonReentrant{
        _createTokenGift(_tokenAddress,_model,_ticketPirce,_endTime,_maxTickets,
            _maxPrizeNum,_allowAddr,_secret,_autoClaim);
        
        if (_injectTicketNum > 0){
            //Calculate number of token to this contract
            _injectTickets(currentId,_injectAddress,_injectTicketNum);
        }
    }

    function injectTickets(uint256 _id,uint256 _ticketNumbers)external virtual override nonReentrant{
        require(_ticketNumbers != 0,"inject no zero");
        require(tokenGiftIdMap[_id].status == Status.Open, "TokenGift is not open");
        if (tokenGiftIdMap[_id].endTime != 0){
            require(block.timestamp < tokenGiftIdMap[_id].endTime, "TokenGift is over time");
        }
        _injectTickets(_id,address(msg.sender),_ticketNumbers);
    }

    function _injectTickets(uint256 _id,address _injectAddress,uint256 _ticketNumbers)internal{
        uint256 amountTokenToTransfer = tokenGiftIdMap[_id].ticketPirce * _ticketNumbers;

        //Transfer cake tokens to this contract
        IERC20(tokenGiftIdMap[_id].ticketToken).safeTransferFrom(address(_injectAddress), address(this), amountTokenToTransfer);
        tokenGiftIdMap[_id].injectTickets += _ticketNumbers;

        if ( injectTicketMap[_id][_injectAddress] == 0){
            injectAddrIndex[_id][tokenGiftIdMap[_id].injectAddrNum] = _injectAddress;
            tokenGiftIdMap[_id].injectAddrNum += 1;
        }
        injectTicketMap[_id][_injectAddress] += _ticketNumbers;

        emit TicketsInject(_id,address(_injectAddress),_ticketNumbers);
    }

    function _fillTicket(uint256 _id,address _receiveAddress,uint256 _ticketNumbers,bool _buy)internal returns(uint256){
            uint256 lastTotalNumbers = 0;
            if (tokenGiftIdMap[_id].userTxNum != 0){
                lastTotalNumbers = ticketMap[_id][tokenGiftIdMap[_id].userTxNum - 1].totalNumbers;
            }
            ticketMap[_id][tokenGiftIdMap[_id].userTxNum] = Ticket({
                    //ticketNumbers: _ticketNumbers,
                    receiveAddress: _receiveAddress,
                    totalNumbers: lastTotalNumbers + _ticketNumbers,
                    buy:_buy
                });

            if (_buy){
                tokenGiftIdMap[_id].buyTickets = tokenGiftIdMap[_id].buyTickets + _ticketNumbers;
            }else{
                tokenGiftIdMap[_id].sendTickets = tokenGiftIdMap[_id].sendTickets + _ticketNumbers;
            }
            
            if (userAddrTicketNumMap[_id][_receiveAddress] == 0){
                userAddrIndex[_id][tokenGiftIdMap[_id].userAddrNum] = _receiveAddress;
                tokenGiftIdMap[_id].userAddrNum += 1;
            }
            tokenGiftIdMap[_id].userTxNum += 1;
            userAddrTicketNumMap[_id][_receiveAddress] = userAddrTicketNumMap[_id][_receiveAddress] + _ticketNumbers;
            return lastTotalNumbers;
    }

    function sendTickets(
        uint256 _id,
        address _receiveAddress,
        uint256 _ticketNumbers
    )external virtual override nonReentrant allowAddress(_id){
        require(tokenGiftIdMap[_id].status == Status.Open, "TokenGift is not open");
        require(tokenGiftIdMap[_id].model == Model.SendModel, "no send ticket model");
        require(_ticketNumbers != 0 ,"ticketNumbers no zero");
        if (tokenGiftIdMap[_id].endTime != 0){
            require(block.timestamp < tokenGiftIdMap[_id].endTime, "TokenGift is over time");
        }
        if (tokenGiftIdMap[_id].maxTickets != 0){
            require(tokenGiftIdMap[_id].buyTickets + tokenGiftIdMap[_id].sendTickets +  _ticketNumbers <= tokenGiftIdMap[_id].maxTickets, "TokenGift is over ticket");
        }
        uint256 lastTotalNumbers = _fillTicket(_id,_receiveAddress,_ticketNumbers,false);
        
        emit TicketsGet(_id,address(msg.sender),_receiveAddress,lastTotalNumbers,_ticketNumbers);
    }

    function buyTickets(
        uint256 _id,
        address _receiveAddress,
        uint256 _ticketNumbers
    )external virtual override nonReentrant allowAddress(_id){
        require(tokenGiftIdMap[_id].status == Status.Open, "TokenGift is not open");
        require(tokenGiftIdMap[_id].model == Model.BuyModel, "no buy ticket model");

        require(_ticketNumbers != 0 ,"ticketNumbers no zero");
        if (tokenGiftIdMap[_id].endTime != 0){
            require(block.timestamp < tokenGiftIdMap[_id].endTime, "TokenGift is over time");
        }
        if (tokenGiftIdMap[_id].maxTickets != 0){
            require(tokenGiftIdMap[_id].buyTickets + tokenGiftIdMap[_id].sendTickets +  _ticketNumbers <= tokenGiftIdMap[_id].maxTickets, "TokenGift is over ticket");
        }

        //Calculate number of token to this contract
        uint256 amountTokenToTransfer = tokenGiftIdMap[_id].ticketPirce * _ticketNumbers;

        //Transfer cake tokens to this contract
        IERC20(tokenGiftIdMap[_id].ticketToken).safeTransferFrom(address(msg.sender), address(this), amountTokenToTransfer);

        uint256 lastTotalNumbers = _fillTicket(_id,_receiveAddress,_ticketNumbers,true);

        emit TicketsPurchase(_id,address(msg.sender),_receiveAddress,lastTotalNumbers,_ticketNumbers);
    }


    function endTokenGift(
        uint256 _id
    )external virtual override onlyOperator nonReentrant{
        require(tokenGiftIdMap[_id].status == Status.Open, "TokenGift is not open");
        //require(block.timestamp > tokenGiftIdMap[_id].endTime || tokenGiftIdMap[_id].buyTickets == tokenGiftIdMap[_id].maxTickets, "TokenGift is over");
        tokenGiftIdMap[_id].status = Status.Close;


        //req Chainlink VRF
        randomGenerator.requestRandomWords(_id);
        emit TokenGiftClosed(_id,block.timestamp,tokenGiftIdMap[_id].buyTickets,tokenGiftIdMap[_id].sendTickets,tokenGiftIdMap[_id].injectTickets);
    }


    function _returnInject(uint256 _id)internal{
        for (uint256 i = 0;i <  tokenGiftIdMap[_id].injectAddrNum;i ++){
            uint256 amountTokenToTransfer = tokenGiftIdMap[_id].ticketPirce * injectTicketMap[_id][injectAddrIndex[_id][i]];
            IERC20(tokenGiftIdMap[_id].ticketToken).safeTransfer(injectAddrIndex[_id][i], amountTokenToTransfer);
        }
    }

    //binary search
    function _getTicketbyIndex(uint256 _id,uint256 _index) internal view returns (Ticket storage){
        require(ticketMap[_id][tokenGiftIdMap[_id].userTxNum - 1].totalNumbers > _index,"index out range");
        uint256 left = 0;
        uint256 right = tokenGiftIdMap[_id].userTxNum - 1;
        //console.log("_index is %d ", _index);
        do{
            uint256 mid = (left + right) / 2;
            if (ticketMap[_id][mid].totalNumbers > _index){
                right = mid ;
            }else if(ticketMap[_id][mid].totalNumbers <= _index){
                left = mid + 1;
            }
            if (left >= right){
                return ticketMap[_id][right];
            }
        }while(true);
        return ticketMap[_id][0];
    }

    function drawPrize(
        uint256 _id,
        uint256 _nonce
    )external virtual override onlyOperator nonReentrant{
        require(tokenGiftIdMap[_id].status == Status.Close, "TokenGift not close");
        tokenGiftIdMap[_id].status = Status.Claimable;
        
        uint256 userTickets = tokenGiftIdMap[_id].buyTickets + tokenGiftIdMap[_id].sendTickets;
        if ( userTickets == 0){
            //return the amount injected
            _returnInject(_id);
            //remove envelope( id);
            emit TokenGiftClaimable(_id,block.timestamp,_nonce,0,0);
            return ;
        }
        //check secret
        if (tokenGiftIdMap[_id].secret != 0 ){
            uint256 secret = uint256(keccak256(abi.encodePacked(_nonce,_id)));
            require(secret == tokenGiftIdMap[_id].secret,"secret error");
        }
        
        //get vrf random
        uint256[] memory randomWords = randomGenerator.getRandomWords(_id);

        uint256 randomWord = uint256(keccak256(abi.encodePacked(randomWords[0],_nonce)));
        
        emit TokenGiftClaimable(_id,block.timestamp,_nonce,randomWords[0],randomWord);

        uint256 drawNum = userTickets;
        if (drawNum > tokenGiftIdMap[_id].maxPrizeNum && tokenGiftIdMap[_id].maxPrizeNum != 0){
            drawNum = tokenGiftIdMap[_id].maxPrizeNum;
        }

        //Calculate winning value
        uint256 totalTickets = tokenGiftIdMap[_id].injectTickets + tokenGiftIdMap[_id].buyTickets;
        if (totalTickets == 0 ){
            return ;
        }
        uint256 amountToken =  tokenGiftIdMap[_id].ticketPirce * totalTickets; 
        uint256[] memory randomsAmount = _getSortRandoms(randomWord,drawNum,amountToken);

        _calculatePrize(_id,drawNum,randomsAmount);
        
        //Use address as unit to collect
        if(tokenGiftIdMap[_id].autoClaim){
            for(uint256 i = 0;i < tokenGiftIdMap[_id].userAddrNum;i++){
                if(amount2claimedMap[_id][userAddrIndex[_id][i]] != 0){
                    _claimPrize(_id,userAddrIndex[_id][i]);
                }
                //delete userAddrTicketNumMap[_id][userAddrIndex[_id][i]];
//delete userAddrIndex[_id][i];
//_removeEnvelope(_id);
            }
        }
        //Non-auto claims are not cleaned up
    }

    function _calculatePrize(uint256 _id,uint256 _drawNum,uint256[] memory _randomsAmount)internal{
        uint256 totalSendAmount = 0;
        uint256 userTickets = tokenGiftIdMap[_id].buyTickets + tokenGiftIdMap[_id].sendTickets;
        //The lottery is drawn based on the total number of user bets or the maximum number of winnings.
        for (uint256 i = 0; i < _drawNum; i++){
            uint256 sendValue = _randomsAmount[i] - totalSendAmount;
            uint256 index = i;
            if (_drawNum != userTickets){
                //Need to randomly generate winning users
                index = _deriveRandom(_randomsAmount[i],i) % userTickets;
                for (;prizedTicketIndex[_id][index] != false;){
                    index++;
                    if (index == userTickets){
                        index = 0;
                    }
                }
            }
            prizedTicketIndex[_id][index] = true;
            Ticket storage ticket = _getTicketbyIndex(_id,index);
            emit PrizeDrawn(_id,ticket.receiveAddress,index,sendValue,tokenGiftIdMap[_id].autoClaim);
            amount2claimedMap[_id][ticket.receiveAddress] += sendValue;
            totalSendAmount += sendValue;
        }        
    }


    function _leftRotate(uint256 _value,uint32 _shift)internal pure returns(uint256){
        return (_value << _shift) | (_value >> (256 - _shift));
    }

    function _deriveRandom(uint256 _seed,uint256 i)internal view returns(uint256){
        //todo:
        uint32 shift = uint32(i % 256);
        return uint256(keccak256(abi.encodePacked(_seed,_leftRotate(_seed,shift),block.timestamp)));
    }

    //Through _seed, a total of _num random numbers are generated, distributed between 0-_range, deduplicated and sorted from small to large
//The last number must be range
//TODO: It will be repeated in extreme cases, resulting in the winning bet and the amount is 0
    function _getSortRandoms(uint256 _seed,uint256 _num,uint256 _range) internal view returns(uint256[] memory){
        uint256[] memory randons = new uint256[](_num);
        uint256 seed = _seed;
        for (uint256 i = 0; i < _num - 1; i++){
            seed = _deriveRandom(seed,i);
            uint256 value = seed % _range;
            uint256 j = i;
            while((j >= 1) && value < randons[j - 1]){
                randons[j] = randons[j-1];
                j--;
            }
            randons[j] = value;
        }
        randons[_num-1] = _range;
        return randons;
    }


    function claimPrize(uint256 _id)external virtual override nonReentrant{
        require(tokenGiftIdMap[_id].status == Status.Claimable, "TokenGift not claimable");
        require(tokenGiftIdMap[_id].autoClaim == false, "TokenGift auto claim");
        _claimPrize(_id,address(msg.sender));
    }

    function _claimPrize(uint256 _id,address _winner)internal {
        require(amount2claimedMap[_id][_winner] != 0, "no prize");
        //Calculate number of token to this contract

        uint256 amountTokenToTransfer = amount2claimedMap[_id][_winner];

        IERC20(tokenGiftIdMap[_id].ticketToken).safeTransfer(_winner, amountTokenToTransfer);
        delete amount2claimedMap[_id][_winner];
        emit ClaimPrize(_id,_winner,amountTokenToTransfer,tokenGiftIdMap[_id].autoClaim);
    }

    /*
function _removeEnvelope(uint256 _id)internal{
for (uint256 i = 0; i < tokenGiftIdMap[_id].injectAddrNum; i++){
delete injectTicketMap[_id][injectAddrIndex[_id][i]];
delete injectAddrIndex[_id][i];
}
for (uint256 i = 0; i < tokenGiftIdMap[_id].userTxNum; i++) {
delete ticketMap[_id][i];
}
delete tokenGiftIdMap[_id];
}*/
//查询指定红包明细
    function viewTokenGiftStatus(uint256 _id) external view  returns (Status){
        return tokenGiftIdMap[_id].status;
    }
    function viewTokenGiftModel(uint256 _id)external view  returns (Model){
        return tokenGiftIdMap[_id].model;
    }
    function viewTokenGiftTicketToken(uint256 _id)external view  returns (address){
        return tokenGiftIdMap[_id].ticketToken;
    }
     function viewTokenGiftTicketPrice(uint256 _id)external view  returns (uint256){
        return tokenGiftIdMap[_id].ticketPirce;
     }
    //Query the latest red envelope id
    function  viewCurrentTokenGiftId() external view returns(uint256){
        return currentId;
    }

 
    //Query red envelope details
    function viewTokenGift(uint256 _id)external view returns (TokenGift memory){
        return tokenGiftIdMap[_id];
    }

    //Query the winning amount that the specified user can claim
    function viewTokenGiftClaimPrize(uint256 _id,address _user)external view returns(uint256){
        return amount2claimedMap[_id][_user];
    }
}

