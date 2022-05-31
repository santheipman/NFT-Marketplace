# Simple NFT marketplace contract

`seller`:
- approve ERC721ProxyTransfer contract to be the operator for his NFT.
- create a sell order using `createOrder()`.

`buyer`:
- approve ERC20ProxyTransfer contract to be the spender for some of his tokens.
- create a sell order using `createOrder()`.
- call `matchAndExecuteOrders()` to match buy order and sell order then execute them (do transfer functions).

## References

- [Smart contracts for Rarible Protocol](https://github.com/rarible/protocol-contracts)
- [Verify Signature | Solidity 0.8](https://www.youtube.com/watch?v=vYwYe-Gv_XI)