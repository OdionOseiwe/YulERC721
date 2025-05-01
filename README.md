# YulERC721 - A Gas-Optimized ERC721 Implementation in Yul

## Overview
YulERC721 is a highly optimized implementation of the ERC721 non-fungible token standard written entirely in Yul (the intermediate language for the Ethereum Virtual Machine). This project demonstrates how to write efficient smart contracts at a low level while maintaining full compatibility with the ERC721 standard.

## Features
- Full ERC721 Compliance: Implements all required ERC721 functions
- Gas Optimization: Significant gas savings compared to Solidity implementations
- Yul Implementation: Written entirely in Yul for maximum control over EVM operations

## Storage Layout
The contract uses the following storage layout:
- slot 0: stores length of the NFT name
- slot 1: stores the name
- slot 2: stores the length of symbol
- slot 3: stores the symbol
- Subsequent slots: tokenApprovals,OperatorApprovals, balances

## Installation
### Prerequisites
- Foundry (forge, cast, anvil)
- Node.js 

1. Install Foundry if it's not already installed:

```
    curl -L https://foundry.paradigm.xyz | bash
    foundryup
```

2. Clone the repository:

```
    git clone https://github.com/OdionOseiwe/YulERC721.git
    cd YulERC721
```

3. Install dependencies:

```
    forge install
```

## Usage 
```
    forge test -vvv
```

## Contributing
Contributions are welcome! Please open an issue or pull request for any improvements or bug fixes.

## License
This project is licensed under the MIT License - see the LICENSE file for details.