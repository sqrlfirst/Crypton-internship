import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import {expect} from "chai";
import {ethers} from "hardhat";
import * as mocha from "mocha-steps";
import {utils, BigNumber, BigNumberish,Contract} from "ethers";

const ZERO_ADDR = '0x0000000000000000000000000000000000000000';
const trans_cash = 100;

describe('BullDog Token contract', () => {
    
    const name = "BullDogToken";
    const symbol = "BDT";
    const totalSupply = 100000000;

    let token: Contract;
    let owner: SignerWithAddress;
    let addr1: SignerWithAddress;
    let addr2: SignerWithAddress;
   
    before(async function() {
        const Token = await ethers.getContractFactory('BullDogToken');
        const tokenDP = await Token.deploy();
        token = await tokenDP.deployed();
        [owner, addr1, addr2] = await ethers.getSigners();
    });

    describe('Deployment', function() {
        mocha.step("Check the token owner", async function() {
            expect(await token.owner()).to.equal(owner.address);
        });

        mocha.step('should assign the total supply of tokens to the owner', async function() {
            let ownerBalance = await token.balanceOf(owner.address);
            expect(await token.totalSupply()).to.equal(ownerBalance);
        });
    });

    describe('Test of Functions transfer() and transferFrom()', function () {
        mocha.step('Test 1 requiring of address not equal to zero', async function() {
            await expect(token.transfer(ZERO_ADDR, 50))
                .to.be.revertedWith("transfer:: address is 0");
        });
        
        mocha.step('Test 2 requiring of allowed amount',async function() {
            await expect(token.connect(addr2).transfer(addr1.address, 50))
                .to.be.revertedWith("transfer:: You need more tokens");
        });
        
        
        mocha.step('Test 3 right balances after transactions',async function() {
            let ownerBalance = await token.balanceOf(owner.address);
            let addr1Balance = await token.balanceOf(addr1.address);
            await token.transfer(addr1.address, trans_cash);
            expect(await token.balanceOf(addr1.address))
                .to.equal(addr1Balance.add(trans_cash));
            expect(await token.balanceOf(owner.address))
                .to.equal(ownerBalance.sub(trans_cash));
        });
        /*
         * TransferFrom() tests begins
        */
        
        mocha.step('Test 4_1 _to requiring != zero address ',async function() {
            await expect(token.transferFrom(addr1.address, ZERO_ADDR, 50))
                .to.be.revertedWith("transferFrom:: address _to is 0");
        });

        mocha.step('Test 4_2 _from requiring != zero address ',async function() {
            await expect(token.transferFrom(ZERO_ADDR, addr1.address, 50))
                .to.be.revertedWith("transferFrom:: address _from is 0");
        });


        mocha.step('Test 5 check allowed _amount bigger than transfered requiring',async function() {
            await token.transfer(addr1.address, 50);
            let addr1Balance = await token.balanceOf(addr1.address);
            await token.approve(addr1.address, addr1Balance);
            expect(await token.allowance(addr1.address))
                .to.be.equal(addr1Balance);
            expect(await token.transferFrom(addr1.address, owner.address, 60))
                .to.be.revertedWith("transferFrom:: amount is not allowed");
        });


        mocha.step('Test 6 Check balances after operations',async function() {
            await token.transfer(addr1.address, trans_cash);
            let addr1Balance = await token.balanceOf(addr1.address);
            await token.connect(addr1.address).approve(addr2.address, trans_cash);
            await token.transferFrom(addr1.address, addr2.address, trans_cash);
            expect(await token.balanceOf(addr2.address))
                .to.be.equal(addr1Balance);
        });

    });

    /* test functions for token operations approving and allowance*/

    describe('Test of functions: approve(), allowance(), decreaseAllowance(), increaseAllowance()', function () {
        /* 
         * approve() tests begins
         */
        mocha.step('Test 1 check _to address != zero requiring',async function() {
            await expect(token.approve(ZERO_ADDR, trans_cash))
                .to.be.revertedWith("approve:: address _to is 0");
        });

        mocha.step('Test 2 balance > _value requiring',async function() {
            await token.transfer(addr1.address, 10);
            expect(await token.connect(addr1.address).approve(addr2.address, 11))
                .to.be.revertedWith("approve:: balance is low");
        });
        
        mocha.step('Test 3 then allowance == amount after',async function() {
            await token.transfer(addr1.address, trans_cash);
            expect(await token.balanceOf(addr1))
                .to.be.equal(trans_cash);
            await token.connect(addr1.address).approve(addr2.address, trans_cash);
            expect(await token.connect(addr1.address).allowance(addr2.address))
                .to.be.equal(trans_cash); 
        });
        
        /*
         * allowance() tests begins
         */
        mocha.step('Test 4 address _to != 0 requiring ',async function() {
            expect(await token.allowance(ZERO_ADDR))
                .to.be.revertedWith("allowance:: address _to is 0");
        });
        
        /*
         * decreaseAllowance() tests begins
         */

        mocha.step('Test 5_1 address _to are not equal 0 requiring ',async function() {
            expect(await token.decreaseAllowance(ZERO_ADDR, trans_cash))
                .to.be.revertedWith("decreaseAllowance:: address _to is 0");
        });
        
        mocha.step('Test 5_2 address sender are not equal 0 requiring ',async function() {
            expect(await token.connect(ZERO_ADDR).decreaseAllowance(addr1.address, trans_cash))
                .to.be.revertedWith("decreaseAllowance:: sender address is 0");
        });

        mocha.step('Test 6 _sub_value is greater than alloweded',async function() {
            await token.transfer(addr1.address, trans_cash);
            expect(await token.balanceOf(addr1))
                .to.be.equal(trans_cash);
            await token.connect(addr1.address).approve(addr2.address, trans_cash);
            expect(await token.connect(addr1.address).allowance(addr2.address))
                .to.be.equal(trans_cash); 
            expect(await token.connect(addr1.address).decreaseAllowance(addr2.address, trans_cash+10))
                .to.be.revertedWith("decreaseAllowance:: _sub_value is bigger than allowance");
        });

        mocha.step('Test 7 _sub_value is less than alloweded(all OK)',async function() {
            await token.transfer(addr1.address, trans_cash);
            expect(await token.balanceOf(addr1))
                .to.be.equal(trans_cash);
            await token.connect(addr1.address).approve(addr2.address, trans_cash);
            expect(await token.connect(addr1.address).allowance(addr2.address))
                .to.be.equal(trans_cash); 
            await token.connect(addr1.address).decreaseAllowance(addr2.address,10);
            expect(await token.connect(addr1.address).allowance(addr2.address))
                .to.be.equal(trans_cash-10); 
        });
         

        /*
        * increaseAllowance() tests begins
        */
       
       mocha.step('Test 8_1 address _to are not equal 0 requiring',async function() {
            expect(await token.increaseAllowance(ZERO_ADDR, trans_cash))
                .to.be.revertedWith("inreaseAllowance:: address _to is 0");
       });
       

        mocha.step('Test 8_2 address sender are not equal 0 requiring',async function() {
            expect(await token.connect(ZERO_ADDR).increaseAllowance(addr1.address, trans_cash))
                .to.be.revertedWith("inreaseAllowance:: address sender is 0");
        });

       mocha.step('Test 9 resulting values are less than spender balance',async function() {
            await token.transfer(addr1.address, trans_cash);
            expect(await token.balanceOf(addr1))
                .to.be.equal(trans_cash);
            await token.connect(addr1.address).approve(addr2.address, trans_cash);
            expect(await token.connect(addr1.address).allowance(addr2.address))
                .to.be.equal(trans_cash); 
            expect(await token.connect(addr1.address).increaseAllowance(addr2.address, 10))
                .to.be.revertedWith("inreaseAllowance:: resulted value is bigger than balance");

       });

       mocha.step('Test 10 resulting values are greater than spender balance', async function() {
            await token.transfer(addr1.address, trans_cash);
            expect(await token.balanceOf(addr1))
                .to.be.equal(trans_cash);
            await token.connect(addr1.address).approve(addr2.address, trans_cash);
            expect(await token.connect(addr1.address).allowance(addr2.address))
                .to.be.equal(trans_cash); 
            await token.connect(addr1.address).decreaseAllowance(addr2.address, 10);
            expect(await token.connect(addr1.address).allowance(addr2.address))
                .to.be.equal(trans_cash-10); 
            await token.connect(addr1.address).increaseAllowance(addr2.address, 10);
            expect(await token.connect(addr1.address).allowance(addr2.address))
                .to.be.equal(trans_cash); 
       });


    });


}); 