# Hardhat Project


Try running some of the following tasks:

## 红包介绍
### 中奖设置：
 + 通过创建红包时的PrizeNum调节中奖奖注数
 + 中奖投注奖金额随机，总数等于抽奖总额度（无抽成下）
 + 若PrizeNum为0，则参与投注数均中奖，此时中奖率100%
 + 若参与投注数小于PrizeNum，实际中奖数即为真实投注数，此时中奖率100%
 + 若参与投注数大于PrizeNum，实际中奖数为PrizeNum
 + 若无人参与投注，所有参与捐赠的奖注将会退回
  
### buy模式红包：
 + 抽奖总额度 = 捐赠额度 + 投注额度
 + 参与抽奖奖注数 = 投注奖注数
 + 适合无第三方捐赠额度的场景，参与者越多，奖金池累积越多
 + 通过createRedEnvelope或者createRedEnvelopeDetail创建

### send模式红包：
 + 抽奖总额度 = 捐赠额度
 + 参与抽奖奖注数 = 派发奖注数
 + 适合存在第三方指定营销的场景，由第三方设置（捐赠）奖金池，并指定许可内的用户参与抽奖
 + 仅能通过createRedEnvelopeDetail创建，且必须绑定sendAllowAddr地址
 + 仅允许sendAllowAddr地址向第三方赠送奖注
 + 推荐将*任务控制器*设置为sendAllowAddr地址


  
## 任务控制器
 + 可作为一类特殊的sendAllowAddr地址，绑定具体红包，用于规定该红包的派发规则
 + 可绑定多类型任务，并为这类任务设置相应的权重
 + 用户可以选择完成任务控制器绑定的任务，并获取红包的抽奖资格
 + 存在两类任务控制模式
  
### 直接投注模式控制器
 + 用户参与任务，完成时通过任务管理器自动投注指定红包活动
 + 参考TaskControlDirect.sol实现

### 任务积分模式控制器 
 + 用户参与任务，完成时获得积分
 + 用户可选择消耗积分，通过任务管理器参与指定红包活动
 + 参考TaskControlWithToken.sol实现
  
## 任务
  + 可支持各种链上活动，需绑定到任务控制器
  + 用户完成任务后，理论上即可获得红包的领取资格
  + 已默认实现链上转账任务/链上质押任务/链上打卡任务/空任务
  + 可支持自定义链上任务

## 跨链
    

## 编译
```shell
yarn hardhat compile
```

## 部署
```shell
yarn hardhat run ./scripts/deploy.ts
```

## 测试
通过eoa账户测试buy模式
```shell
yarn hardhat test ./test/eoa-buy.ts
```

通过eoa账户测试send模式
```shell
yarn hardhat test ./test/eoa-send.ts
```

通过任务积分模式控制器测试buy模式
```shell
yarn hardhat test ./test/taskControlWithToken-buy.ts
```

通过任务积分模式控制器测试send模式
```shell
yarn hardhat test ./test/taskControlWithToken-send.ts
```

通过直接投注模式控制器测试buy模式
```shell
yarn hardhat test ./test/taskControlDirect-buy.ts
```

通过直接投注模式控制器测试send模式
```shell
yarn hardhat test ./test/taskControlDirect-send.ts
```

## 添加task（以任务积分模式控制器为例）
1. 实现ItaskCallee接口的task合约
```
function taskCall(address sender,bytes calldata data) external payable  returns(uint256);
```

2. 将实现并部署的task合约绑定到TaskControl合约,设置权重
```
function setTask(address _taskAddr,uint256 _weight)external;
```

3. 通过TaskControl合约执行task任务，获取token
```
function mintToken(address _taskAddr,address _receiveAddress,bytes calldata _data) external;
```

4. 消耗token，参与指定红包，领取奖注
```
function getTicket(uint256 _id,address _receiveAddress,uint256 _ticketNumbers)external;
```

**其中buy模式红包需要TaskControl合约拥有足够购买投注的资产*

**send模式红包需要TaskControl合约被绑定为sendAllowAddr*

