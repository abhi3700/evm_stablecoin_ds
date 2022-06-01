# Implementation

## Trove

```c
struct Trove {
    tokens[],
    tokenAmts[]
}
```

## Whitelist

* Change the License from `UNLICENSED`to `MIT`.
* Change the solidity version from `0.6.11` to `0.8.6`.
* Modified the paths of files imported.
* Removed the usage of "SafeMath.sol". So, arithmetic functions like `add`, `sub` is removed.
* All the storage variables used are prefixed with `diamondStorage()` function of "LibHexaDiamond.sol" file.
* File formatted as per "Solidity+Hardhat".

**"LibHexaDiamond.sol"**

* The state variables of this contract are moved here into diamond storage struct.

```solidity
    struct CollateralParams {
        // Safety ratio
        uint256 ratio; // 10**18 * the ratio. i.e. ratio = .95 * 10**18 for 95%. More risky collateral has a lower ratio
        address oracle;
        uint256 decimals;
        address priceCurve;
        uint256 index;
        bool active;
        bool isWrapped;
        address defaultRouter;
    }

    struct DiamondStorage {
        ...
        IWhitelist whitelist;
        IActivePool activePool;
        IDefaultPool defaultPool;
        // IStabilityPool stabilityPool;
        ICollSurplusPool collSurplusPool;
        // status of addresses set
        bool addressesSet;
        ...
        ...
    }
```

## ActivePool

* Change the License from `UNLICENSED`to `MIT`.
* Change the solidity version from `0.6.11` to `0.8.6`.
* Modified the paths of files imported.
* Removed the usage of "SafeMath.sol". So, arithmetic functions like `add`, `sub` is removed.
* renamed `YUSDDebt` to `aUSMDebt`.
* `poolColl` state variable is replaced by `apoolColl`.
* All the storage variables used are prefixed with `diamondStorage()` function of "LibHexaDiamond.sol" file.
* All the require functions are referenced here from "LibHexaDiamond.sol" file.
* File formatted as per "Solidity+Hardhat".
* renamed the functions:
  * `increaseUSMDebt()`
  * `decreaseUSMDebt()`
* Added a utility function called `getName()`.

**"IActivePool.sol"**

* Commented the events (repetitive)

**"LibHexaDiamond.sol"**

* The state variables of this contract are moved here into diamond storage struct.

```solidity
address borrowerOperationsAddress;
address troveManagerAddress;
address activePoolAddress;
address stabilityPoolAddress;
address defaultPoolAddress;
address troveManagerLiquidationsAddress;
address troveManagerRedemptionsAddress;
address collSurplusPoolAddress;
address hexaFinanceTreasury;
IWhitelist whitelist;

newColls apoolColl;
uint256 aUSMDebt; // USM debt of active pool
```

* The `require` functions are moved here.
* `whitelist` storage variable is moved here.
* `newColls` struct is moved here.

**"HexaCustomBase.sol"**

* The “HexaCustomBase.sol” has been refactored to consider gas optimization. And this is achieved by using `calldata` instead of `memory` data location.
* `whitelist` storage variable used is referenced from "LibHexaDiamond.sol".
* `newColls` struct, used is referenced from "LibHexaDiamond.sol".

---

## DefaultPool

* Change the License from `UNLICENSED`to `MIT`.
* Change the solidity version from `0.6.11` to `0.8.6`.
* Modified the paths of files imported.
* Removed the usage of "SafeMath.sol". So, arithmetic functions like `add`, `sub` is removed.
* renamed `YUSDDebt` to `dUSMDebt`.
* `poolColl` state variable is replaced by `dpoolColl`.
* All the require functions are referenced here from "LibHexaDiamond.sol" file.
  * NEW: `_requireCallerIsActivePool()`
* File formatted as per "Solidity+Hardhat".
* renamed the functions:
  * `increaseUSMDebt()`
  * `decreaseUSMDebt()`
* Added a utility function called `getName()`.

**"IDefaultPool.sol"**

* Commented the events (repetitive)

**"LibHexaDiamond.sol"**

* The state variables of this contract are moved here into diamond storage struct.

```solidity
address borrowerOperationsAddress;
address troveManagerAddress;
address activePoolAddress;
address stabilityPoolAddress;
address defaultPoolAddress;
address troveManagerLiquidationsAddress;
address troveManagerRedemptionsAddress;
address collSurplusPoolAddress;
address hexaFinanceTreasury;
address whitelistAddress;
IWhitelist whitelist;

newColls dpoolColl;
uint256 dUSMDebt; // USM debt of default pool
```

* The `require` functions are moved here.
* `whitelist` storage variable is moved here.
* `newColls` struct is moved here.

**"HexaCustomBase.sol"**

All required changes are done during "ActivePool.sol" file modification.

## StabilityPool

This has been dropped as of now. Because there is no plan to use inflationary model for native token (MOJO) in order to incentivize people to stake the minted USM.

Instead the minted stablecoin is supposed to have utility in DApps like gaming, payment sector.

So, we can direct the minted stablecoins (USM) to pools like Liquidity, Lending/Borrowing in DEXes (Uniswap, Curve, etc.) and other DeFi protocols (Aave, Compound, dy/dx, etc.).

## BorrowerOperations

> Here, the connected contracts are called here & its functions are used to change the respective state variables.
> 
> NO storage variables as such except:
> * `BOOTSTRAP_PERIOD`
> * `deploymentTime`
> 
> The local variables (used in the functions) are maintained in variable container structs so as to avoid `CompilerError: Stack too deep`.

* Change the License from `UNLICENSED`to `MIT`.
* Change the solidity version from `0.6.11` to `0.8.6`.
* Modified the paths of files imported.
* Removed the usage of "SafeMath.sol". So, arithmetic functions like `add`, `sub` is removed.
* Added a utility function called `getName()`.
* `stabilityPoolAddress` dereferenced here as there is no plan to include "Stability Pool".
* Following structs moved to "LibMojoDiamond.sol" file:
  * `CollateralData`
  * `DepositFeeCalc`
  * `AdjustTrove_Params`
  * `LocalVariables_adjustTrove`
  * `LocalVariables_openTrove`
  * `CloseTrove_Params`
  * `ContractsCache`
* Enum `BorrowerOperation` moved to "LibMojoDiamond.sol" file
* `YUSDTokenAddressChanged` event renamed to `USMTokenAddressChanged`
* `YUSDBorrowingFeePaid` event renamed to `USMBorrowingFeePaid`

**"IUSMToken.sol"**

* Changed the name from "IYUSDToken.sol" to "IUSMToken.sol".
