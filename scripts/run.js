

const main = async () => {

    const [owner, randomAddress] = await hre.ethers.getSigners();
    const coolDomainsContractFactory = await hre.ethers.getContractFactory("CoolDomains");
    const coolDomainsContract = await coolDomainsContractFactory.deploy("momo");

    await coolDomainsContract.deployed();
    console.log("Cool Domains contract deployed to: " + coolDomainsContract.address);
    console.log("Contract deployed by: " + owner.address);

    let txn = await coolDomainsContract.register("sxbady", { value: hre.ethers.utils.parseEther('0.1') });
    await txn.wait();

    const domainOwner = await coolDomainsContract.getAddress("sxbady");
    console.log("Owner of domain: ", domainOwner);

    //txn = await coolDomainsContract.connect(randomAddress).setRecord("sxbady", "I take your domain, buahah");

    const balance = await hre.ethers.provider.getBalance(coolDomainsContract.address);
    console.log("Contract Balance: ", hre.ethers.utils.formatEther(balance));

};

const runMain = async () => {
    try {
        await main();
        process.exit(0);
    } catch (error) {
        console.log(error);
        process.exit(1);
    }

};

runMain();