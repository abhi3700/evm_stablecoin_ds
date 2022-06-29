# Instruction

## Objective

* Create a `upgradeable`, `ownable`, `pausable` __Polygon's native stablecoin/borrowing__ protocol smart contract.
* Follow [__diamond standard__](https://github.com/ethereum/EIPs/issues/2535) so as to never get this error: "exceeding contract size limit" i.e. `24 KB`.

## Features

### Deployment params

### Trove

* A Trove contains a struct with 2 arrays - collateral token addresses & token amount. Both must have same lengths.

### Commission

* Deposit fees
  * It is charged during the deposit of collateral
* Borrowing fees
  * It is charged during the deposit of collateral, but as loan along with stablecoin

### Anyone

### DEX

* Deposit the minted stablecoins to [Curve](https://curve.fi/) like protocol's stableswap pools.

### Protocol owner

* claim fees via `claimFees()`
  * This can be done at any point of time after deposit has been done.

### Utils

* Get recommended coins for collateral:
  * calculation would be done either on-chain (using Chainlink Oracle) or off-chain
  * return the collateral coins' address.
  * This depends on Bonding curve equation.

## Diamond standard

It consists of 3 parts:

1. __Proxy contract__ which is called the _diamond_. Here file is named "CFDiamond.sol"
2. __Diamond storage__ is stored at the _position_ (basically represented by a `keccak256 hash`) set via a string `"diamond.standard.diamond.storage"`. Here, all the storage variables & contract address for functions is stored & updated when a facet is updated.
3. __Implementation contract__ which is called _facet_. Each facet is deployed into an address. This contract only contains functions, events, modifiers. Proxy contract makes a delegate call to the facets in order to update its own storage i.e. diamond storage.

> NOTES:
>
> * Whenever the proxy contract is called, it does `delegatecall` to the logic/implementation SC i.e. facet(s) to run their code on the proxy contract's storage variables (present inside diamond storage). Hence, the storage variables is updated.
> * In order to use any state variables from "Diamond storage" inside the functions of _facet_, just use the position & call the state variables.

### Storage position

* Here, we set the `DIAMOND_STORAGE_POSITION` param same using an string input - "diamond.standard.diamond.storage" for the entire proxy contract. We would set different position only if there are different structs created for storage.
* After this, we take the `keccak256` hash of the entire string.

## Unit Testing


## Dependencies

* OpenZeppelin
* Diamond Standard

## Testing framework

* Hardhat using Typescript language.

## Networks

* localhost
* Testnet
  * Rinkeby
  * Kovan
* Mainnet
  * Ethereum
  * Polygon

## Glossary

* PSC: Polygon Stablecoin
* SF: Stability Factor
