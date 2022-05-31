const { ethers } = require('hardhat');
const { expect } = require('chai');

describe("Exchange", function () {
    let owner;
    let seller;
    let buyer;

    let erc20Token;
    let erc721Token;

    let debugExchange;
    let verifySignatureLib;

    beforeEach(async function () {
        [owner, seller, buyer] = await ethers.getSigners();

        const ERC20Token = await ethers.getContractFactory("ERC20Token");
        erc20Token = await ERC20Token.deploy(buyer.address, 1000);

        const ERC721Token = await ethers.getContractFactory("ERC721Token");
        erc721Token = await ERC721Token.deploy(seller.address, 3);

        const VerifySignatureLib = await ethers.getContractFactory("VerifySignature");
        verifySignatureLib = await VerifySignatureLib.deploy();

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
        // const sellOrder = await debugExchange.orderToTuple(await debugExchange.connect(seller)).createOrder(
            // erc721Token.address, 3, erc20Token.address, 100, true
        // ));
        const outp = await debugExchange.connect(seller).wrappedCreateOrder(
            erc721Token.address, 3, erc20Token.address, 100, true
        );
        console.log(outp);
        // console.log(sellOrder);

        // console.log(            sellOrder['ERC721Address'],
        //     sellOrder.tokenID,
        //     sellOrder.ERC20Address,
        //     sellOrder.ERC20TokenAmount,
        //     sellOrder.isSeller,
        //     sellOrder.orderID);
        // await seller.signMessage(
        //     sellOrder.ERC721Address,
        //     sellOrder.tokenID,
        //     sellOrder.ERC20Address,
        //     sellOrder.ERC20TokenAmount,
        //     sellOrder.isSeller,
        //     sellOrder.orderID
        // );
    });
});