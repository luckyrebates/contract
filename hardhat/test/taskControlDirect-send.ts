import {
    loadFixture,
  } from "@nomicfoundation/hardhat-toolbox/network-helpers";
import hre from "hardhat";
import {deployTetherUSD,TetherUSD} from "../scripts/TetherUSD-deploy"
import {deployRandomGenerator,TestRandomGenerator} from "../scripts/RandomGenerator-deploy"
import { LuckyTokenGift,deployLuckyTokenGift } from "../scripts/LuckyTokenGift-deploy";
import { deployTaskControlDirect,TaskControlDirect } from "../scripts/TaskControlDirect-deploy";
import { deployEmptyTask,EmptyTask } from "../scripts/task/EmptyTask-deploy";

import type { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
import { expect } from "chai";
import  {
    ZeroAddress
  } from "ethers";



describe("task control with token: sends ticket", function (){
    let usdt:TetherUSD;
    let luckyTokenGift:LuckyTokenGift;
    let randomGenerator:TestRandomGenerator;
    let taskControl:TaskControlDirect;
    let owner:HardhatEthersSigner;
    let otherAccount:HardhatEthersSigner;
    
    before(async function(){
        //Initialize contract
        usdt = await loadFixture(deployTetherUSD);
        const addr1 = await usdt.getAddress();
        console.log('usdt address:',addr1);

        randomGenerator = await loadFixture(deployRandomGenerator);
        const addr2 = await randomGenerator.getAddress();
        console.log('randomGenerator address:',addr2);
        
        luckyTokenGift = await loadFixture(deployLuckyTokenGift);
        const addr3 = await luckyTokenGift.getAddress();
        console.log('tokenGift address:',addr3);

        taskControl = await loadFixture(deployTaskControlDirect);
        const addr4 = await luckyTokenGift.getAddress();
        console.log('taskControl address:',addr4);

        await (await randomGenerator.setOperatorAddressList(await luckyTokenGift.getAddress(),true)).wait();

        [owner,otherAccount] = await hre.ethers.getSigners();

        
    });
    describe("bind task",function(){
        let emptyTask:EmptyTask;
        before(async function(){
            //Deploy specific tasks: empty task: just execute the contract at any address
            emptyTask = await loadFixture(deployEmptyTask);
            const emptyTaskAddr = await emptyTask.getAddress();
            console.log('emptyTask address:',emptyTaskAddr);
            
            //Bind the empty task to the task control and set the weight to 1
            const setTask = taskControl.setTask(emptyTaskAddr,1n);
            await expect(setTask).not.to.be.reverted;
            await (await setTask).wait();       
            
        });
        describe("tokenGift",function(){
            let id:bigint;
            before(async function(){
                //Authorize user address to transfer money to red envelope contract
                const luckyTokenGiftAddr = await luckyTokenGift.getAddress();
                const approveCall = usdt.approve(luckyTokenGiftAddr,1000000000);
                await expect(approveCall).not.to.be.reverted;
                await (await approveCall).wait() ;
    
    
                //Create a send mode red envelope and bind the send address to task control
                const taskControlAddr = await taskControl.getAddress();
                const usdtAddr = await usdt.getAddress();
                let sendModel = 2n;
                const createTokenGiftDetail = luckyTokenGift.createTokenGiftDetail(usdtAddr,sendModel,1000000n,0n,0n,20n,ZeroAddress,0n,taskControlAddr,0n,true);
                await expect(createTokenGiftDetail).not.to.be.reverted;
                
                await (await createTokenGiftDetail).wait();
    
                id = await luckyTokenGift.viewCurrentTokenGiftId();
                const balance = await usdt.balanceOf(owner);
                console.log('id:%d owner balance:%d',id,balance);
            });
            
            it("inject", async function () {    
                //Owner donates 10 notes
                const injectTickets = luckyTokenGift.injectTickets(id,10n);
                await expect(injectTickets).not.to.be.reverted;
                const recept = await (await injectTickets).wait();
                
                const balance = await usdt.balanceOf(owner);
                console.log('id:%d inject tx:%s owner balance:%d',id,recept?.hash,balance);
            });
            it("owner getTicket",async function () {
                const emptyTaskAddr = await emptyTask.getAddress()
                //Pass the contract parameters through abi.encode and then pass them in
                const data = hre.ethers.AbiCoder.defaultAbiCoder().encode(["uint256"],[10n]);
                //owner performs tasks and obtains tickets
                const getTicket =  taskControl.getTicket(id,emptyTaskAddr,owner,data);
                await expect(getTicket).not.to.be.reverted;
                const recept = await (await getTicket).wait();
    
            });
    
            it("otherAccount getTicket",async function () {
                const emptyTaskAddr = await emptyTask.getAddress()
                //Pass the contract parameters through abi.encode and then pass them in
                const data = hre.ethers.AbiCoder.defaultAbiCoder().encode(["uint256"],[5n]);
                
               //otherAccount performs tasks and obtains tickets
               const getTicket =  taskControl.connect(otherAccount).getTicket(id,emptyTaskAddr,otherAccount,data);
                
               await expect(getTicket).not.to.be.reverted;
               const recept = await (await getTicket).wait();
            });
    
        });
        
        
        describe("end tokenGift",function(){
            it("end", async function (){
                //End bet
                const id = await luckyTokenGift.viewCurrentTokenGiftId();
                const endTokenGift = luckyTokenGift.endTokenGift(id);
    
                await expect(endTokenGift).not.to.be.reverted;
                const recept = await (await endTokenGift).wait();
    
                const ownerBalance = await usdt.balanceOf(owner)
                const otherAccountBalance = await usdt.balanceOf(otherAccount)
                
                console.log('id:%d end tx:%s owner Balance:%d otherAccount balance:%d',id,recept?.hash,ownerBalance,otherAccountBalance);
            });
            it("fulfillRandomWords", async function (){
                //Inject random numbers
                const id = await luckyTokenGift.viewCurrentTokenGiftId();
                
                const fulfillRandomWords = randomGenerator.fulfillRandomWords(id,[1234567n]);
                
                await expect(fulfillRandomWords).not.to.be.reverted;
                const recept = await (await fulfillRandomWords).wait();
                
                console.log('id:%d fulfillRandomWords tx:%s ',id,recept?.hash);
            });
        });
        describe("drawPrize tokenGift",function(){
            //Lottery draw
            it("drawPrize", async function () {
                const id = await luckyTokenGift.viewCurrentTokenGiftId();
                const drawPrize = luckyTokenGift.drawPrize(id,0n);
                await expect(drawPrize).not.to.be.reverted;
                const recept = await (await drawPrize).wait();   
                
                const ownerBalance = await usdt.balanceOf(owner)
                const otherAccountBalance = await usdt.balanceOf(otherAccount)
    
    
                console.log('id:%d drawPrize tx:%s owner Balance:%d otherAccount balance:%d',id,recept?.hash,ownerBalance,otherAccountBalance);
            });
        });
    });
    
});