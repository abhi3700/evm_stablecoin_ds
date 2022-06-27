# Implementation

## Trove

```c
struct Trove {
    tokens[],
    tokenAmts[]
}
```

## Whitelist

> Contains all the whitelisted collateral assets. Only these assets can be used as collateral into Troves.

- Change the License from `UNLICENSED`to `MIT`.
- Change the solidity version from `0.6.11` to `0.8.6`.
- Modified the paths of files imported.
- Removed the usage of "SafeMath.sol". So, arithmetic functions like `add`, `sub` is removed.
- All the storage variables used are prefixed with `diamondStorage()` function of "LibMojoDiamond.sol" file.
- File formatted as per "Prettier".
- Now, `setAddresses()` function is available as 1 function only, inside "MojoDiamond.sol" file.

**"LibMojoDiamond.sol"**

- The state variables of this contract are moved here into diamond storage struct.

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

> Contains all the active collateral with TCR ≥ 110% (set percentage by protocol) & active debt

- Change the License from `UNLICENSED`to `MIT`.
- Change the solidity version from `0.6.11` to `0.8.6`.
- Modified the paths of files imported.
- Removed the usage of "SafeMath.sol". So, arithmetic functions like `add`, `sub` is removed.
- renamed `YUSDDebt` to `aUSMDebt`.
- `poolColl` state variable is replaced by `apoolColl`.
- All the storage variables used are prefixed with `diamondStorage()` function of "LibMojoDiamond.sol" file.
- All the require functions are referenced here from "LibMojoDiamond.sol" file.
- File formatted as per "Prettier".
- renamed the functions:
  - `increaseUSMDebt()`
  - `decreaseUSMDebt()`
- Added a utility function called `getName()`.
- Now, `setAddresses()` function is available as 1 function only, inside "MojoDiamond.sol" file.

**"IActivePool.sol"**

- Commented the events (repetitive)

**"LibMojoDiamond.sol"**

- The state variables of this contract are moved here into diamond storage struct.

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

- The `require` functions are moved here.
- `whitelist` storage variable is moved here.
- `newColls` struct is moved here.

**"MojoCustomBase.sol"**

- The “MojoCustomBase.sol” has been refactored to consider gas optimization. And this is achieved by using `calldata` instead of `memory` data location.
- `whitelist` storage variable used is referenced from "LibMojoDiamond.sol".
- `newColls` struct, used is referenced from "LibMojoDiamond.sol".

---

## DefaultPool

> Contains all the liquidated collateral & closed debt

- Change the License from `UNLICENSED`to `MIT`.
- Change the solidity version from `0.6.11` to `0.8.6`.
- Modified the paths of files imported.
- Removed the usage of "SafeMath.sol". So, arithmetic functions like `add`, `sub` is removed.
- renamed `YUSDDebt` to `dUSMDebt`.
- `poolColl` state variable is replaced by `dpoolColl`.
- All the require functions are referenced here from "LibMojoDiamond.sol" file.
  - NEW: `_requireCallerIsActivePool()`
- File formatted as per "Prettier".
- renamed the functions:
  - `increaseUSMDebt()`
  - `decreaseUSMDebt()`
- Added a utility function called `getName()`.
- Now, `setAddresses()` function is available as 1 function only, inside "MojoDiamond.sol" file.

**"IDefaultPool.sol"**

- Commented the events (repetitive)

**"LibMojoDiamond.sol"**

- The state variables of this contract are moved here into diamond storage struct.

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

- The `require` functions are moved here.
- `whitelist` storage variable is moved here.
- `newColls` struct is moved here.

**"MojoCustomBase.sol"**

All required changes are done during "ActivePool.sol" file modification.

## StabilityPool

This has been dropped as of now. Because there is no plan to use inflationary model for native token (MOJO) in order to incentivize people to stake the minted USM.

Instead the minted stablecoin is supposed to have utility in DApps like gaming, payment sector.

So, we can direct the minted stablecoins (USM) to pools like Liquidity, Lending/Borrowing in DEXes (Uniswap, Curve, etc.) and other DeFi protocols (Aave, Compound, dy/dx, etc.).

## BorrowerOperations

> Contains all the external functions like Open/Adjust/Close trove
>
> Here, the connected contracts are called here & its functions are used to change the respective state variables.
>
> NO storage variables as such except:
>
> - `BOOTSTRAP_PERIOD`
> - `deploymentTime`
>
> The local variables (used in the functions) are maintained in variable container structs so as to avoid `CompilerError: Stack too deep`.

- Change the License from `UNLICENSED`to `MIT`.
- Change the solidity version from `0.6.11` to `0.8.6`.
- Modified the paths of files imported.
- Removed the usage of "SafeMath.sol". So, arithmetic functions like `add`, `sub` is removed.
- Added a utility function called `getName()`.
- Now, `setAddresses()` function is available as 1 function only, inside "MojoDiamond.sol" file.
- `stabilityPoolAddress` dereferenced here as there is no plan to include "Stability Pool".
- Following structs moved to "LibMojoDiamond.sol" file:
  - `CollateralData`
  - `DepositFeeCalc`
  - `AdjustTrove_Params`
  - `LocalVariables_adjustTrove`
  - `LocalVariables_openTrove`
  - `CloseTrove_Params`
  - `ContractsCache`
- Enum `BorrowerOperation` moved to "LibMojoDiamond.sol" file
- `YUSDTokenAddressChanged` event renamed to `USMTokenAddressChanged`
- `YUSDBorrowingFeePaid` event renamed to `USMBorrowingFeePaid`
- `_requireValidMaxFeePercentage` modified by removing recovery mode var.
- In `_openTroveInternal` function,
  - disabled recovery mode check
  - `if` condition removed for recovery mode check & the the snippet modified to:
  ```solidity
      vars.USMFee = _triggerBorrowingFee(
          contractsCache.troveManager,
          contractsCache.usmToken,
          _USMAmount,
          vars.VC, // here it is just VC in, which is always larger than USM amount
          _maxFeePercentage
      );
      _maxFeePercentage = _maxFeePercentage.sub(vars.USMFee.mul(DECIMAL_PRECISION).div(vars.VC));
  ```
  - `if-else` condition removed as recovery mode is disabled:
  ```solidity
          if (vars.isRecoveryMode) {
            _requireICRisAboveCCR(vars.ICR);        // ICR > CCR
          } else {
              _requireICRisAboveMCR(vars.ICR);        // ICR > MCR
              vars.newTCR = _getNewTCRFromTroveChange(vars.VC, true, vars.compositeDebt, true); // bools: coll increase, debt increase
              _requireNewTCRisAboveCCR(vars.newTCR);  // new_TCR > CCR
          }
  ```

**"IUSMToken.sol"**

- Changed the name from "IYUSDToken.sol" to "IUSMToken.sol".

**LiquityMath.sol**

- changed the LICENSE to MIT
- compiler version changed from `0.6.11` to `0.8.6`.
- type changed from contract to library.
- `DECIMAL_PRECISION`, `HALF_DECIMAL_PRECISION` are shifted to Diamond library file.

**LiquityBase.sol**

It is inherited by BorrowerOperations, TroveManager files.

- changed the LICENSE to MIT
- compiler version changed from `0.6.11` to `0.8.6`.
- all the referenced state variables are called from Diamond lib (instead of defining here) in functions.
- Disabled recovery mode i.e functions like `_checkPotentialRecoveryMode`, `_checkRecoveryMode`.
- Defined as `abstract` type.
  > Note: the type `contract` type is chosen here mainly for Facets, Proxy Contract (Diamond).
