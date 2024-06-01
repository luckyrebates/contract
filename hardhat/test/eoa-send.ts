import {
    loadFixture,
  } from "@nomicfoundation/hardhat-toolbox/network-helpers";
import hre from "hardhat";
import {deployTetherUSD,TetherUSD} from "../scripts/TetherUSD-deploy"
import {deployRandomGenerator,TestRandomGenerator} from "../scripts/RandomGenerator-deploy"
import { LuckyTokenGift,deployLuckyTokenGift  } from "../scripts/LuckyTokenGift-deploy";
import { expect } from "chai";
import  {
    ZeroAddress
  } from "ethers";
import type { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";

describe("TokenGift:send model", function (){
    let usdt:TetherUSD;
    let luckyTokenGift:LuckyTokenGift;
    let randomGenerator:TestRandomGenerator;
    let owner:HardhatEthersSigner;
    let otherAccount:HardhatEthersSigner;
    before(async function(){
        //Initialize contract
        usdt = await loadFixture(deployTetherUSD);
        const addr1 = await usdt.getAddress()
        console.log('usdt address:',addr1);

        randomGenerator = await loadFixture(deployRandomGenerator);
        const addr2 = await randomGenerator.getAddress();
        console.log('randomGenerator address:',addr2);
        

        luckyTokenGift = await loadFixture(deployLuckyTokenGift);
        const addr3 = await luckyTokenGift.getAddress();
        console.log('tokenGift address:',addr3);

        await (await randomGenerator.setOperatorAddressList(await luckyTokenGift.getAddress(),true)).wait();

        [owner,otherAccount] = await hre.ethers.getSigners();
    });

    describe("start tokenGift",function(){
        let id:bigint;
        before(async function(){
            //Authorize user address to transfer money to red envelope contract
            const addr = await luckyTokenGift.getAddress();
            const approveCall = usdt.approve(addr,1000000000);
            await expect(approveCall).not.to.be.reverted;

            await (await approveCall).wait();

            const myTokenAddr = await usdt.getAddress();

            //To create a red envelope, use the send mode, and only allow otherAccount addresses to send. There is no limit on the deadline and the total number of purchased notes. The maximum number of winnings is 20 notes.
//Donate 10 bets at the time of creation and through the owner address
            let sendModel = 2n;
            const createTokenGiftDetail = luckyTokenGift.createTokenGiftDetail(myTokenAddr,sendModel,1000000n,0n,0n,20n,owner,10n,otherAccount,0n,true);
            await expect(createTokenGiftDetail).not.to.be.reverted;
            
            await (await createTokenGiftDetail).wait();

            id = await luckyTokenGift.viewCurrentTokenGiftId();
            const balance1 = await usdt.balanceOf(owner);
            const balance2 = await usdt.balanceOf(otherAccount);
            console.log('id:%d balance1:%d balance2:%d',id,balance1,balance2);
        });
        
        it("inject", async function () {
            //Donate 10 Notes
            const injectTickets = luckyTokenGift.injectTickets(id,10n);
            await expect(injectTickets).not.to.be.reverted;
            const recept = await (await injectTickets).wait();
            
            const balance1 = await usdt.balanceOf(owner);
            const balance2 = await usdt.balanceOf(otherAccount);
            console.log('id:%d inject tx:%s balance1:%d balance2:%d',id,recept?.hash,balance1,balance2);
        });
        it("buy",async function () {
            //Try to purchase a bet, but the send mode does not allow the bet to be purchased.
            const buyTickets =  luckyTokenGift.buyTickets(id,owner,20n);
            
            await expect(buyTickets).to.be.reverted;
            console.log('owner can not buy');
                    
        });

        it("send by owner",async function () {
            //Try to send bonus note, non-binding address does not allow sending
            const sendTickets = luckyTokenGift.sendTickets(id,owner,20n)
            expect(sendTickets).to.be.reverted;
            console.log('owner can not send');
            
        });

        it("send by otherAccount",async function () {
            //Bind address send bonus note
            const sendTickets = luckyTokenGift.connect(otherAccount).sendTickets(id,otherAccount,20n)
            expect(sendTickets).not.to.be.reverted;
            const recept = await (await sendTickets).wait();

            const balance1 = await usdt.balanceOf(owner);
            const balance2 = await usdt.balanceOf(otherAccount);
            console.log('id:%d send tx:%s balance1:%d balance2:%d',id,recept?.hash,balance1,balance2);
        });
    });
    
    
    describe("end tokenGift",function(){
        it("end", async function (){
            //End bet
            const id = await luckyTokenGift.viewCurrentTokenGiftId();
            const endTokenGift = luckyTokenGift.endTokenGift(id);

            await expect(endTokenGift).not.to.be.reverted;
            const recept = await (await endTokenGift).wait();

            const balance1 = await usdt.balanceOf(owner);
            const balance2 = await usdt.balanceOf(otherAccount);
            console.log('id:%d end tx:%s balance1:%d balance2:%d',id,recept?.hash,balance1,balance2);
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
        it("drawPrize", async function () {
            //Lottery draw
            const id = await luckyTokenGift.viewCurrentTokenGiftId();
            const drawPrize = luckyTokenGift.drawPrize(id,0n);
            await expect(drawPrize).not.to.be.reverted;
            const recept = await (await drawPrize).wait();   
   
            const balance1 = await usdt.balanceOf(owner);
            const balance2 = await usdt.balanceOf(otherAccount);
            console.log('id:%d drawPrize tx:%s balance1:%d balance2:%d',id,recept?.hash,balance1,balance2);
        });
    });
});