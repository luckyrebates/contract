import {
    loadFixture,
  } from "@nomicfoundation/hardhat-toolbox/network-helpers";
import hre from "hardhat";
import {deployTetherUSD,TetherUSD} from "../scripts/TetherUSD-deploy"
import {deployRandomGenerator,TestRandomGenerator} from "../scripts/RandomGenerator-deploy"
import type { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
import {LuckyTokenGift,deployLuckyTokenGift } from "../scripts/LuckyTokenGift-deploy";
import { expect } from "chai";


describe("TokenGift:buy model", function (){
    let usdt:TetherUSD;
    let luckyTokenGift:LuckyTokenGift;
    let randomGenerator:TestRandomGenerator;
    let owner:HardhatEthersSigner;
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

        await (await randomGenerator.setOperatorAddressList(await luckyTokenGift.getAddress(),true)).wait();
        
        [owner] = await hre.ethers.getSigners();
        
    });

    
    describe("start tokenGift",function(){
        let id:bigint;
        before(async function(){
            //Authorize user address to transfer money to red envelope contract
            const addr = await luckyTokenGift.getAddress();
            const approveCall = usdt.approve(addr,1000000000);
            await expect(approveCall).not.to.be.reverted;
            await (await approveCall).wait();
            
            //Create a red envelope and use the buy mode. There is no limit on the deadline and the total number of purchased bets. The maximum number of winnings is 20 bets.
            const createTokenGiftCall = luckyTokenGift.createTokenGift(0n,0n,20n,0n);
            await expect(createTokenGiftCall).not.to.be.reverted;
            
            let tx = await (await createTokenGiftCall).wait();
            console.log('tx: ',tx?.hash);
            
            //Query the created red envelope ID
            id = await luckyTokenGift.viewCurrentTokenGiftId();
            
            const balance = await usdt.balanceOf(owner);
            console.log('id:%d start balance:%d',id,balance);
            
        });
        
        it("inject", async function () {
            //Donate 10 Notes
            const injectTickets = luckyTokenGift.injectTickets(id,10n);
            await expect(injectTickets).not.to.be.reverted;
            const recept = await (await injectTickets).wait();
            
            const balance = await usdt.balanceOf(owner);
            console.log('id:%d inject tx:%s balance:%d',id,recept?.hash,balance);
        });
        it("buy",async function () {
            //Buy 20 Notes
            const buyTickets =  luckyTokenGift.buyTickets(id,owner,20n);
            
            await expect(buyTickets).not.to.be.reverted;
            const recept = await (await buyTickets).wait();

            const balance = await usdt.balanceOf(owner);
            console.log('id:%d buy tx:%s  balance:%d',id,recept?.hash,balance);
        });

        it("send",async function () {
            //Buy mode cannot send
            const sendTickets = luckyTokenGift.sendTickets(id,owner,30n)
            expect(sendTickets).to.be.reverted;
        });
    });
    
    
    describe("end tokenGift",function(){
        it("end", async function (){
            //End bet
            const id = await luckyTokenGift.viewCurrentTokenGiftId();
            const endTokenGift = luckyTokenGift.endTokenGift(id);

            await expect(endTokenGift).not.to.be.reverted;
            const recept = await (await endTokenGift).wait();

            const balance = await usdt.balanceOf(owner)
            
            console.log('id:%d end tx:%s balance:%d',id,recept?.hash,balance);
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
   
            const balance = await usdt.balanceOf(owner)
            
            console.log('id:%d drawPrize tx:%s balance:%d',id,recept?.hash,balance);
        });
    });
});