# stablecoin/borrowing protocol

Polygon's Native stablecoin

An `upgradable`, `ownable`, `pausable` **polygon stablecoin/borrowing** smart contract which can be used as a protocol layer.

## About

- It's a Polygon's native stablecoin protocol smart contract.
- For more, refer [Wiki](./docs/wiki).
- To launch the protocol, follow [Getting Started](./docs/wiki/getting_started.md) manual.

## Usage

### Installation

Install node packages

```console
$ yarn install
```

### Build

Build the smart contracts

```console
$ yarn compile
```

### Test

Run unit tests

```console
$ yarn test
```

### TypeChain

Compile the smart contracts and generate TypeChain artifacts:

```console
$ yarn typechain
```

### Lint Solidity

Lint the Solidity code:

```console
$ yarn lint:sol
```

### Lint TypeScript

Lint the TypeScript code:

```console
$ yarn lint:ts
```

### Coverage

Generate the code coverage report:

```console
$ yarn coverage
```

### Report Gas

See the gas usage per unit test and average gas per method call:

```console
$ REPORT_GAS=true yarn test
```

### Clean

Delete the smart contract artifacts, the coverage reports and the Hardhat cache:

```console
$ yarn clean
```

### Deploy

**Sequence**:

1. Deploy the "Hexadiamond.sol" contract with facets & libraries.
   - "DefaultPool.sol"
   - "ActivePool.sol"
   - "Whitelist.sol"
2. Set addresses using `setAddresses()` function (inside Diamond Proxy SC)
   - only Owner

<!-- TODO: HexaCustomBase.sol to be either set as address inside the constructor of diamond. And then create a onlyOwner function setHexaCustomBase() -->

3. Add assets as whitelisted for respective pools (active, default, stability, colSurplus) from `Whitelist::addCollateral` function. Whenever an asset is added, the asset is updated in the pools as well.

#### localhost

<!-- ```console
// on terminal-1
$ npx hardhat node

// on terminal-2
$ yarn hardhat deploy:Stablecoin --network localhost
``` -->

#### ETH Testnet - Rinkeby

- Environment variables: Create a `.env` file with its values in [.env.example](./.env.example)
- Deploy the contracts

<!-- ```console
yarn hardhat deploy:Stablecoin --network rinkeby
``` -->

#### ETH Mainnet

- Environment variables: Create a `.env` file with its values in [.env.example](./.env.example)
- Deploy the contracts

<!-- ```console
yarn hardhat deploy:Escrow --network mainnet
``` -->
