// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;

import "../libs/LibMojoDiamond.sol";

interface IMojoCustomBase {
    // --- Events ---

    // --- Functions ---

    // function _sumColls(
    //     LibMojoDiamond.newColls memory _coll1,
    //     LibMojoDiamond.newColls memory _coll2
    // ) internal view returns (LibMojoDiamond.newColls memory finalColls);

    // function _sumColls(
    //     LibMojoDiamond.newColls memory _coll1,
    //     address[] calldata tokens,
    //     uint256[] calldata amounts
    // ) internal view returns (LibMojoDiamond.newColls memory);

    // function _sumColls(
    //     address[] calldata tokens1,
    //     uint256[] calldata amounts1,
    //     address[] calldata tokens2,
    //     uint256[] calldata amounts2
    // ) internal view returns (LibMojoDiamond.newColls memory);

    function _leftSumColls(
        LibMojoDiamond.newColls memory _coll1,
        address[] calldata _tokens,
        uint256[] calldata _amounts
    ) external view returns (uint256[] memory);

    function _leftSubColls(
        LibMojoDiamond.newColls calldata _coll1,
        address[] calldata _subTokens,
        uint256[] calldata _subAmounts
    ) external view returns (uint256[] memory);

    function _subColls(
        LibMojoDiamond.newColls calldata _coll1,
        address[] calldata _tokens,
        uint256[] calldata _amounts
    ) external view returns (LibMojoDiamond.newColls memory finalColls);
}
