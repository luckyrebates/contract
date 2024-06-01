## 浏览器
### sepolia网络浏览器:
https://sepolia.etherscan.io/

### avalanche-fuji网络浏览器：
https://testnet.snowtrace.io/

### 跨链浏览器：
https://ccip.chain.link/

## 使用指南

### 创建及处理红包
+ 通过红包合约操作员地址直接调用LuckyRedEnvelopeV2合约接口



### 任务积分模式(buy模式)
#### 用户获取奖注token
+ 用户（前端）直接调用TaskControlWithToken合约的mintToken接口,可根据用户参与的任务选择传入具体的task合约地址

#### 用户注销奖注token参与红包
+ 用户（前端）直接调用TaskControlWithToken合约的getTicket接口,将会消耗1*10^decimals个token换取1注具体红包活动





### 直接投注模式(send模式)
#### 用户直接参与任务获取指定红包投注
+ 用户（前端）直接调用TaskControlDirect合约的getTicket接口,可根据用户参与的任务选择传入具体的task合约地址
+ 需传入红包id，完成指定任务后将直接获取对应数量的红包投注
+ 获取的红包投注数量取决于任务权重及预设decimals




## 其他
### 如何给mintToken接口的data字段传参数
```
function mintToken(address _taskAddr,address _receiveAddress,bytes calldata data) external;
```
在TaskControl合约的mintToken接口中，data需根据具体task的实际业务合约处理传参
```
function taskCall(address _sender,bytes calldata _data) external  onlyOperator returns(uint256){
        (uint256 value) = abi.decode(_data,(uint256));
        return _taskCall(_sender,value);
    }
```
参考PayTask中，具体data数据通过(uint256 value) = abi.decode(_data,(uint256))被解析为uint256，因此在传参时，需要对原始数据进行encode处理，打包为bytes data。js参考实现:
```
const data = hre.ethers.AbiCoder.defaultAbiCoder().encode(["uint256"],[1000000n]);
```