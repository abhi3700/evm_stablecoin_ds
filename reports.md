# Reports

## Coverage
<!-- TODO: Copy paste the coverage console output -->

```console
❯ yarn coverage
yarn run v1.22.18
$ hardhat coverage --solcoverjs ./.solcover.js --temp build --network hardhat

Version
=======
> solidity-coverage: v0.7.21

Instrumenting for coverage...
=============================

> ERC20Token.sol

Compilation:
============

Generating typings for: 10 artifacts in dir: ./build/typechain/ for target: ethers-v5
Successfully generated 15 typings!
Compiled 10 Solidity files successfully

Network Info
============
> HardhatEVM: v2.9.3
> network:    hardhat

No need to generate any newer typings.


  ERC20 Token contract
    Ownable
      ✔ Should have the correct owner
      ✔ Owner is able to transfer ownership
    Pausable
      ✔ Owner is able to pause when NOT paused
      ✔ Owner is able to unpause when already paused
      ✔ Owner is NOT able to pause when already paused
      ✔ Owner is NOT able to unpause when already unpaused
    Mint
      ✔ Succeeds when owner mints token
      ✔ Reverts when non-owner mints token
      ✔ Reverts when owner mints zero token
      ✔ Reverts when owner mints token to zero address
      ✔ Reverts when paused
    Burn
      ✔ Succeeds when self burns token
      ✔ Succeeds when others burns token for you
      ✔ Reverts when self burns zero token
      ✔ Reverts when burnt from zero address
      ✔ Reverts when paused


  16 passing (2s)

-----------------|----------|----------|----------|----------|----------------|
File             |  % Stmts | % Branch |  % Funcs |  % Lines |Uncovered Lines |
-----------------|----------|----------|----------|----------|----------------|
 contracts/      |      100 |      100 |      100 |      100 |                |
  ERC20Token.sol |      100 |      100 |      100 |      100 |                |
-----------------|----------|----------|----------|----------|----------------|
All files        |      100 |      100 |      100 |      100 |                |
-----------------|----------|----------|----------|----------|----------------|

> Istanbul reports written to ./coverage/ and ./coverage.json
✨  Done in 10.21s.
```

## Deployment
<!-- TODO: Copy paste the deployment console output -->

```console
// M-1
❯ npx hardhat run deployment/deploy.ts --network rinkeby                                                                                                                 ⏎
No need to generate any newer typings.
ERC20 token SC deployed to:  0x583790285609943225395c091e5D657E946574F0
The transaction that was sent to the network to deploy the token contract: 0x0e591038a4fac2b303167038d2f347cdd38fc0800b1d6587f7490fc5833d47a4

// M-2
❯ yarn hardhat deploy:ERC20Token --network rinkeby
yarn run v1.22.18
$ /Users/abhi3700/F/coding/github_repos/evm_boilerplate/node_modules/.bin/hardhat deploy:ERC20Token --network rinkeby
ERC20 token SC deployed to:  0x583790285609943225395c091e5D657E946574F0
The transaction that was sent to the network to deploy the token contract: 0x0e591038a4fac2b303167038d2f347cdd38fc0800b1d6587f7490fc5833d47a4
✨  Done in 23.16s.
```

## Verify
<!-- TODO: Copy paste the verification console output -->

```console
❯ yarn verify rinkeby 0x583790285609943225395c091e5D657E946574F0 "Health Token" "HLT"                                                                ⏎
yarn run v1.22.18
$ hardhat verify --network rinkeby 0x583790285609943225395c091e5D657E946574F0 'Health Token' HLT
Nothing to compile
No need to generate any newer typings.
Successfully submitted source code for contract
contracts/ERC20Token.sol:ERC20Token at 0x583790285609943225395c091e5D657E946574F0
for verification on Etherscan. Waiting for verification result...

Successfully verified contract ERC20Token on Etherscan.
https://rinkeby.etherscan.io/address/0x583790285609943225395c091e5D657E946574F0#code
✨  Done in 27.48s.
```
