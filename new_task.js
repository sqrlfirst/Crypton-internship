task("new_task", "call new task")
    // .addParam("new_param", "New param")
    .setAction(async function (args, hre, runSuper) {

        const accounts = await ethers.getSigners();

        const network = hre.network.name;

        const fs = require('fs');
        const dotenv = require('dotenv');
        const envConfig = dotenv.parse(fs.readFileSync(`.env-${network}`))
        for (const k in envConfig) {
            process.env[k] = envConfig[k]
        }

        const token = await hre.ethers.getContractAt("BEP20", "0x4b107a23361770534bd1839171bbf4b0eb56485c");
        console.log("Token address:", token.address);

        decimal = await token.decimals();
        console.log(decimal);

        balance = await token.balanceOf(accounts[0].address);
        console.log("Balance:", balance / 10 ** decimal)

        await token.transfer(process.env.ADDRESS, ethers.utils.parseEther("100.0"))
        console.log("Done.")
    });