const {expect} = require('chai');
const { ethers } = require('ethers');

describe('Token contract', () => {
   let Token, token, owner, addr1, addr2;
   
    beforeEach(async () => {
        Token = await ethers.getContractFactory('BullDogToken');
        token = await Token.deploy();
        [owner, addr1, addr2, _] = await ethers.getSigners();
    });

    describe('Deployment', () => {
        it('Should set the right owner', async () => {
            expect(await token.owner()).to.equal(owner.address);
        });

        it('should assign the total supply of tokens to the owner', async () => {
            const ownerBalance = await token.balanceOf(owner.address);
            expect(await token.totalSupply()).to.equal(ownerBalance);
        });
    });

    describe('Transactions', () => {
        it('Should transfer tokens between accounts', async () => {
            await token.transfer(addr1.address, 50);
            const addr1Balance = await token.balanceOf(addr1.address);
            expect(addr1Balance).to.equal(50);

            await token.connect(addr1).transfer(addr2.address, 50);
            const addr2Balance = await token.balanceOf(addr2.address);
            expect(addr2Balance).to.equal(50);
        });

        // it('Should fail if sender doesnt have enough tokens', async () => {
        //     const initialBalanceOwner = await token.balanceOf(owner.address);
        // 
        //     await expect(
        //         token
        //             .connect(addr1)
        //             .transfer(owner.address, 1)
        //     )
        //         .to
        //         .be
        //         .revertedWith('You need more tokens');
        //     expect(
        //         await token.balanceOf(owner.address)
        //     )
        //         .to
        //         .equal(initialOwnerBalance)
        // 
        // });

        it('Should transfer tokens between addresses', async () => {
            // give some tokens to addr1 then transfer to addr2
            await token.transfer(addr1.address, 50);
            const addr1Balance = await token.balanceOf(addr1.address);
            expect(addr1Balance).to.equal(50);

            await token.connect(addr1).approve(addr2.address, 25);
            await token.transferFrom(addr1.address, addr2.address, 25);
            const addr2Balance = await token.balanceOf(addr2.address);
            expect(addr2Balance).to.equal(25);
        });

        it('should catch revert', async () => {
            await expect(token.connect(owner).transfer(owner.address, 1))
        });
    });

    /* test functions for token operations approving and allowance*/

    describe('test functions for token operations approving and allowance', () => {
        it('Should approve tokens amount', async () => {
            /*
             send 100 to addr 1
            */
            await token.transfer(addr1.address, 100);
            const addr1Balance = await token.balanceOf(addr1.address);
            expect(addr1Balance).to.equal(100);

            await token.connect(addr1).approve(addr2.address, 50);
            // const allowedValue = token.connect(addr1).allowance(addr2.address);
            // expect(allowedValue).to.equal(50);

            await token.connect(addr1).decreaseAllowance(addr2.address, 25);
            // allowedValue = token.connect(addr1).allowance(addr2.address);
            // expect(allowedValue).to.equal(25);

            await token.connect(addr1).increaseAllowance(addr2.address, 50);
            // allowedValue = token.connect(addr1).allowance(addr2.address);
            // expect(allowedValue).to.equal(75);

            // await expect(
            //     token.connect(addr1).increaseAllowance(addr2.address, 50)
            // )
            //     .to.be.revertedWith("inreaseAllowance:: resulted value is bigger than balance");
            
            await expect(
                token.connect(addr1).decreaseAllowance(addr2.address, 100)
            )
                .to.be.revertedWith("decreaseAllowance:: _sub_value is bigger than allowance");
        });
    });


});