# Implementation

## Trove

```c
struct Trove {
    tokens[],
    tokenAmts[]
}
```

## ActivePool

`ActivePool` contains duplicate functions which are repetitive in all the pool contracts - `ActivePool`, `DefaultPool`, `StabilityPool`.

1. The state variables is shifted over to “LibHexaDiamond.sol” file.
2. The `require` functions is shifted to “LibHexaDiamond.sol” file.
3. The state variables from “LibHexaDiamond.sol”’s diamond storage are called in this contract.
4. The “HexaCustomBase.sol” has been refactored to consider gas optimization. And this is achieved by using `calldata` instead of `memory` data location.
