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
