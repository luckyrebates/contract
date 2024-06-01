## Browser
### sepolia web browser:
https://sepolia.etherscan.io/

### avalanche-fuji web browser:
https://testnet.snowtrace.io/

### Cross-chain browser:
https://ccip.chain.link/

## User guide

### Create and process red envelopes
+ Directly call the LuckyRedEnvelopeV2 contract interface through the red envelope contract operator address

### Task points mode (buy mode)
#### User obtains bonus tokens
+ The user (front end) directly calls the mintToken interface of the TaskControlWithToken contract, and can select the specific task contract address according to the task the user participates in

#### User cancels the bonus token to participate in the red envelope
+ The user (front end) directly calls the getTicket interface of the TaskControlWithToken contract, which will consume 1*10^decimals tokens in exchange for 1 specific red envelope activity

### Direct betting mode (send mode)
#### Users directly participate in tasks to obtain designated red envelope bets
+ Users (front-end) directly call the getTicket interface of the TaskControlDirect contract, and can choose to pass in specific task contract addresses according to the tasks the user participates in
+ The red envelope id needs to be passed in, and the corresponding number of red envelope bets will be directly obtained after completing the specified task
+ The number of red envelope bets obtained depends on the task weight and the preset decimals

## Others
### How to pass parameters to the data field of the mintToken interface
```
function mintToken(address _taskAddr,address _receiveAddress,bytes calldata data) external;
```
In the mintToken interface of the TaskControl contract, data needs to be processed and passed according to the actual business contract of the specific task
```
function taskCall(address _sender,bytes calldata _data) external onlyOperator returns(uint256){
(uint256 value) = abi.decode(_data,(uint256));
return _taskCall(_sender,value);
}
```
Refer to PayTask, the specific data is parsed into uint256 through (uint256 value) = abi.decode(_data,(uint256)), so when passing parameters, the original data needs to be encoded and packaged into bytes data. js reference implementation:
```
const data = hre.ethers.AbiCoder.defaultAbiCoder().encode(["uint256"],[1000000n]);
```