// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

import "./ERC20TransferProxy.sol";
import "./ERC721TransferProxy.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "hardhat/console.sol";

contract ExchangeCollection {
    struct Order {
        address ERC721Address;
        uint256 tokenID;
        address ERC20Address;
        uint256 ERC20TokenAmount;
        bool isSeller; // comment
        uint256 orderID; // comment
    }
}

library VerifySignature {
    function getMessageHash(ExchangeCollection.Order memory _message) public pure returns (bytes32) {
        return keccak256(
            abi.encodePacked(
                _message.ERC721Address,
                _message.tokenID,
                _message.ERC20Address,
                _message.ERC20TokenAmount,
                _message.isSeller,
                _message.orderID
            )
        );
    }

    function getEthSignedMessageHash(bytes32 _messageHash) public pure returns (bytes32){
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
    }

    function verify(address _signer, ExchangeCollection.Order memory _message, bytes memory signature) public pure {
        bytes32 messageHash = getMessageHash(_message);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        require(recoverSigner(ethSignedMessageHash, signature) == _signer, 'incorrect signature');
    }

    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature) public pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig) public pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(sig.length == 65, "invalid signature length");

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }
}

contract Exchange is ExchangeCollection {
    // orderID => bool
    mapping(uint256 => bool) public isOrderCompleted;
    ERC20TransferProxy public erc20TransferProxy;
    ERC721TransferProxy public erc721TransferProxy;
    uint256 public counter;

    constructor() {
        erc20TransferProxy = new ERC20TransferProxy();
        erc721TransferProxy = new ERC721TransferProxy();
        counter = 0;
    }

    // createOrder: return order dict
    function createOrder(
        address _ERC721Address, uint256 _tokenID, address _ERC20Address,
        uint256 _ERC20TokenAmount, bool _isSeller) public returns (Order memory) 
    {
        if (_isSeller) {
            require(IERC721(_ERC721Address).getApproved(_tokenID) == address(erc721TransferProxy), 
                "seller hasn't approved ERC721TransferProxy yet");
        } else {
            require(IERC20(_ERC20Address).allowance(msg.sender, address(erc20TransferProxy)) == _ERC20TokenAmount, 
                "buyer hasn't approved correct amount to ERC20TransferProxy yet");
        }

        counter = counter + 1;
        
        return Order({
                ERC721Address: _ERC721Address,
                tokenID: _tokenID,
                ERC20Address: _ERC20Address,
                ERC20TokenAmount: _ERC20TokenAmount,
                isSeller: _isSeller,
                orderID: counter
        });
    }

    // buyer: approve then hit buy, input price
    function matchAndExecuteOrders(
        address seller, Order memory sellOrder, bytes memory sellerSig, 
        address buyer, Order memory buyOrder, bytes memory buyerSig) public 
    {
        require(isOrderCompleted[sellOrder.orderID] == false);
        require(isOrderCompleted[buyOrder.orderID] == false);
        
        require(sellOrder.ERC721Address == buyOrder.ERC721Address);
        require(sellOrder.tokenID == buyOrder.tokenID);
        require(sellOrder.ERC20Address == buyOrder.ERC20Address);
        require(sellOrder.ERC20TokenAmount == buyOrder.ERC20TokenAmount);

        require(sellOrder.isSeller == true);
        require(buyOrder.isSeller == false);

        VerifySignature.verify(seller, sellOrder, sellerSig);
        VerifySignature.verify(buyer, buyOrder, buyerSig);

        isOrderCompleted[sellOrder.orderID] = true;
        isOrderCompleted[buyOrder.orderID] = true;

        erc721TransferProxy.transferERC721(sellOrder.ERC721Address, seller, buyer, sellOrder.tokenID);
        erc20TransferProxy.transferERC20(buyOrder.ERC20Address, buyer, seller, buyOrder.ERC20TokenAmount);
    }
}

contract DebugExchange is Exchange {

    // function orderToTuple(Order memory order) public pure returns (address, uint256, address, uint256, bool, uint256) {
    //     return (order.ERC721Address, order.tokenID, order.ERC20Address, 
    //         order.ERC20TokenAmount, order.isSeller, order.orderID);
    // }

    // function tupleToOrder(
    //     address _ERC721Address, uint256 _tokenID, address _ERC20Address, 
    //     uint256 _ERC20TokenAmount, bool _isSeller, uint256 _orderID) public pure returns (Order memory) 
    // {
    //     return Order({
    //             ERC721Address: _ERC721Address,
    //             tokenID: _tokenID,
    //             ERC20Address: _ERC20Address,
    //             ERC20TokenAmount: _ERC20TokenAmount,
    //             isSeller: _isSeller,
    //             orderID: _orderID
    //     });
    // }

    function getERC20TransferProxyAddress() public view returns (address) {
        return address(erc20TransferProxy);
    }

    function getERC721TransferProxyAddress() public view returns (address) {
        return address(erc721TransferProxy);
    }

    // function wrappedMatchAndExecuteOrders(
    //     address seller, bytes memory sellerSig, address buyer, bytes memory buyerSig,
    //     address sERC721Address, uint256 sTokenID, address sERC20Address, uint256 sERC20TokenAmount, bool sIsSeller, uint256 sOrderID,
    //     address bERC721Address, uint256 bTokenID, address bERC20Address, uint256 bERC20TokenAmount, bool bIsSeller, uint256 bOrderID
    // ) public
    // {
    //     Order memory sellOrder = Order({
    //             ERC721Address: sERC721Address,
    //             tokenID: sTokenID,
    //             ERC20Address: sERC20Address,
    //             ERC20TokenAmount: sERC20TokenAmount,
    //             isSeller: sIsSeller,
    //             orderID: sOrderID
    //     });
    //     Order memory buyOrder = Order({
    //             ERC721Address: bERC721Address,
    //             tokenID: bTokenID,
    //             ERC20Address: bERC20Address,
    //             ERC20TokenAmount: bERC20TokenAmount,
    //             isSeller: bIsSeller,
    //             orderID: bOrderID
    //     });

    //     matchAndExecuteOrders(
    //         seller, sellOrder, sellerSig, 
    //         buyer, buyOrder, buyerSig
    //     );
    // }

    function wrappedCreateOrder(
        address _ERC721Address, uint256 _tokenID, address _ERC20Address,
        uint256 _ERC20TokenAmount, bool _isSeller) public returns (address, uint256, address, uint256, bool, uint256) 
    {
        Order memory order = createOrder(
            _ERC721Address, _tokenID, _ERC20Address,
            _ERC20TokenAmount, _isSeller
        );

        return (order.ERC721Address, order.tokenID, order.ERC20Address, 
            order.ERC20TokenAmount, order.isSeller, order.orderID);
    }

}