const { ethers } = require('hardhat');
const { expect } = require('chai');

describe("Exchange", function () {
    let seller;
    let buyer;

    let erc20Token;
    let erc721Token;

    let debugExchange;
    let debugVerifySignatureLib;
    let verifySignatureLib;

    beforeEach(async function () {
        [_, seller, buyer] = await ethers.getSigners();

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

        // seller create sell order
        // why use callStatic? -> https://ethereum.stackexchange.com/questions/88119/i-see-no-way-to-obtain-the-return-value-of-a-non-view-function-ethers-js
        const sellOrder  = await debugExchange.connect(seller).callStatic.createOrder(
            erc721Token.address, 3, erc20Token.address, 100, true
        );

        const signature = getSignatureUsingEthersJS(seller, sellOrder);

        // check if debugVerifySignatureLib.wrappedVerify can recover the right signer
        await debugVerifySignatureLib.wrappedVerify(seller.address, getBytes(sellOrder), signature);
    });

    it("Match and excecute orders", async function () {
        const _tokenID = 3;
        const _price = 100;

        // seller approves ERC721TransferProxy to spend his ERC721 (NFT)
        await erc721Token.connect(seller).approve(debugExchange.getERC721TransferProxyAddress(), _tokenID);

        // seller create sell order
        const sellOrder = await debugExchange.connect(seller).callStatic.createOrder(
            erc721Token.address, _tokenID, erc20Token.address, _price, true
        );

        // buyer approves ERC20TransferProxy to spend his ERC20
        await erc20Token.connect(buyer).approve(debugExchange.getERC20TransferProxyAddress(), 100);

        // buyer create buy order
        const buyOrder  = await debugExchange.connect(buyer).callStatic.createOrder(
            erc721Token.address, _tokenID, erc20Token.address, _price, false
        );

        // match orders and execute them
        await debugExchange.wrappedMatchAndExecuteOrders(
            seller.address, getBytes(sellOrder), getSignatureUsingEthersJS(seller, sellOrder),
            buyer.address, getBytes(buyOrder), getSignatureUsingEthersJS(buyer, buyOrder)
        );

        // now buyer is the new owner of the sold NFT
        expect(await erc721Token.ownerOf(_tokenID)).to.equal(buyer.address);

        // seller received `_price` ERC20 tokens
        expect(await erc20Token.balanceOf(seller.address)).to.equal(_price);
    });

    function getBytes(order) {
        return ethers.utils.AbiCoder.prototype.encode(
            ['address', 'uint256', 'address', 'uint256', 'bool', 'uint256'],
            [order.ERC721Address, order.tokenID.toString(), order.ERC20Address, order.ERC20TokenAmount.toString(), order.isSeller, order.orderID.toString()]
        );
	}

    async function getSignatureUsingEthersJS(signer, order) {
        // hash the message
        const messageHash = ethers.utils.solidityKeccak256(
            ['address', 'uint256', 'address', 'uint256', 'bool', 'uint256'],
            [order.ERC721Address, order.tokenID.toString(), order.ERC20Address, order.ERC20TokenAmount.toString(), order.isSeller, order.orderID.toString()]
        );

        // get signature produced by etherjs library
        const signature = await signer.signMessage(ethers.utils.arrayify(messageHash));

        return signature;
    }
});