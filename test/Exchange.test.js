const { ethers } = require('hardhat');
const { expect } = require('chai');

describe("Exchange", function () {
    let owner;
    let seller;
    let buyer;

    let erc20Token;
    let erc721Token;

    let debugExchange;
    let debugVerifySignatureLib;
    let verifySignatureLib;

    beforeEach(async function () {
        [owner, seller, buyer] = await ethers.getSigners();

        const ERC20Token = await ethers.getContractFactory("ERC20Token");
        erc20Token = await ERC20Token.deploy(buyer.address, 1000);

        const ERC721Token = await ethers.getContractFactory("ERC721Token");
        erc721Token = await ERC721Token.deploy(seller.address, 3);

        const VerifySignatureLib = await ethers.getContractFactory("VerifySignature");
        verifySignatureLib = await VerifySignatureLib.deploy();

        const DebugVerifySignatureLib = await ethers.getContractFactory("DebugVerifySignature", {
            libraries: {
                VerifySignature: (await verifySignatureLib).address,
            },
        });
        debugVerifySignatureLib = await DebugVerifySignatureLib.deploy();

        const DebugExchange = await ethers.getContractFactory("DebugExchange", {
            libraries: {
                VerifySignature: (await verifySignatureLib).address,
            },
        });
        debugExchange = await DebugExchange.deploy();
    });

    it("Verify signature", async function () {

        // seller approves ERC721TransferProxy to spend his ERC721 (NFT)
        await erc721Token.connect(seller).approve(debugExchange.getERC721TransferProxyAddress(), 3);

        const {ERC721Address, tokenID, ERC20Address, ERC20TokenAmount, isSeller, orderID} = await debugExchange.connect(seller).callStatic.createOrder(
            erc721Token.address, 3, erc20Token.address, 100, true
        );

        const messageHash = ethers.utils.solidityKeccak256(
            ['address', 'uint256', 'address', 'uint256', 'bool', 'uint256'],
            [ERC721Address, tokenID.toString(), ERC20Address, ERC20TokenAmount.toString(), isSeller, orderID.toString()]
        );

        const orderData = ethers.utils.AbiCoder.prototype.encode(
            ['address', 'uint256', 'address', 'uint256', 'bool', 'uint256'],
            [ERC721Address, tokenID.toString(), ERC20Address, ERC20TokenAmount.toString(), isSeller, orderID.toString()]
        );

        // get signature produced by etherjs library
        const signature = await seller.signMessage(ethers.utils.arrayify(messageHash));

        // check if debugVerifySignatureLib.wrappedVerify can recover the right signer
        await debugVerifySignatureLib.wrappedVerify(seller.address, orderData, signature);
    });
});