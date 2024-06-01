# Hardhat Project

Try running some of the following tasks:

## Red Envelope Introduction
### Winning Settings:
+ Adjust the number of winning bets by setting PrizeNum when creating a red envelope
+ The winning bet amount is random, and the total amount is equal to the total amount of the lottery (without commission)
+ If PrizeNum is 0, all participating bets win, and the winning rate is 100%
+ If the number of participating bets is less than PrizeNum, the actual number of winning bets is the real number of bets, and the winning rate is 100%
+ If the number of participating bets is greater than PrizeNum, the actual number of winning bets is PrizeNum
+ If no one participates in the betting, all the participating donations will be returned

### Buy mode red envelope:
+ Total lottery amount = Donation amount + Betting amount
+ Number of participating lottery bets = Number of betting bets
+ Suitable for scenarios without third-party donation amount, the more participants, the more accumulated bonus pool
+ Created by createRedEnvelope or createRedEnvelopeDetail

### Send mode red envelope:
+ Total amount of the lottery = donation amount
+ Number of lottery tickets = number of lottery tickets distributed
+ Suitable for scenarios where there is third-party designated marketing, the third party sets up (donates) the bonus pool and specifies the users within the license to participate in the lottery
+ Can only be created through createRedEnvelopeDetail, and must be bound to the sendAllowAddr address
+ Only the sendAllowAddr address is allowed to give lottery tickets to third parties
+ It is recommended to set the *task controller* to the sendAllowAddr address

## Task controller
+ Can be used as a special type of sendAllowAddr address, bind a specific red envelope, and use it to specify the distribution rules of the red envelope
+ Can bind multiple types of tasks and set corresponding weights for such tasks
+ Users can choose to complete the tasks bound to the task controller and obtain the lottery qualification for the red envelope
+ There are two types of task control modes

### Direct betting mode controller
+ Users participate in the task, and automatically bet on the specified red envelope activity through the task manager when completed
+ Refer to TaskControlDirect.sol for implementation

### Task points mode controller
+ Users participate in tasks and receive points when they complete them
+ Users can choose to consume points and participate in designated red envelope activities through the task manager
+ Refer to TaskControlWithToken.sol for implementation

## Tasks
+ Supports various on-chain activities and needs to be bound to the task controller
+ After the user completes the task, he or she can theoretically obtain the qualification to receive the red envelope
+ On-chain transfer tasks/on-chain staking tasks/on-chain clock-in tasks/empty tasks have been implemented by default
+ Supports custom on-chain tasks

## Cross-chain

## Compile
```shell
yarn hardhat compile
```

## Deploy
```shell
yarn hardhat run ./scripts/deploy.ts
```

## Test
Test the buy mode through the eoa account
```shell
yarn hardhat test ./test/eoa-buy.ts
```

Test the send mode through the eoa account
```shell
yarn hardhat test ./test/eoa-send.ts
```

Test buy mode through task points mode controller
```shell
yarn hardhat test ./test/taskControlWithToken-buy.ts
```

Test send mode through task points mode controller
```shell
yarn hardhat test ./test/taskControlWithToken-send.ts
```

Test buy mode through direct betting mode controller
```shell
yarn hardhat test ./test/taskControlDirect-buy.ts
```

Test send mode through direct betting mode controller
```shell
yarn hardhat test ./test/taskControlDirect-send.ts
```

## Add task (taking task points mode controller as an example)
1. Implement the task contract of ItaskCallee interface
```
function taskCall(address sender,bytes calldata data) external payable returns(uint256);
```

2. Bind the implemented and deployed task contract to the TaskControl contract and set the weight
```
function setTask(address _taskAddr,uint256 _weight)external;
```

3. Execute the task through the TaskControl contract and obtain the token
```
function mintToken(address _taskAddr,address _receiveAddress,bytes calldata _data) external;
```

4. Consume tokens, participate in the designated red envelope, and receive the bonus ticket
```
function getTicket(uint256 _id,address _receiveAddress,uint256 _ticketNumbers)external;
```

**The buy mode red envelope requires the TaskControl contract to have enough assets to buy bets*

**The send mode red envelope requires the TaskControl contract to be bound to sendAllowAddr*