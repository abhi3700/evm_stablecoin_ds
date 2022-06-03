// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

// import "../libs/math/BaseMath.sol";
// import "./SafeMath.sol";         // Not needed for compiler version >= 0.8.0
import "../interfaces/IERC20.sol";

import "../libs/LibMojoDiamond.sol";

// NOTE: if this hits the contract size limit, 
// then create "LibMojoDiamond2.sol" & shift the `newColls` struct & 
// `whitelist` state var to there with a new diamond storage position

// NOTE: contract changed to library
library MojoCustomBase {
    // using SafeMath for uint256;          // TODO: clear

    // Collateral math
    // gets the sum of _coll1 and _coll2
    function _sumColls(LibMojoDiamond.newColls memory _coll1, LibMojoDiamond.newColls memory _coll2)
        internal
        view
        returns (LibMojoDiamond.newColls memory finalColls)
    {
        LibMojoDiamond.newColls memory coll3;

        LibMojoDiamond.DiamondStorage storage ds = LibMojoDiamond
            .diamondStorage();

        coll3.tokens = ds.whitelist.getValidCollateral();
        uint256 coll1Len = _coll1.tokens.length;
        uint256 coll2Len = _coll2.tokens.length;
        uint256 coll3Len = coll3.tokens.length;
        coll3.amounts = new uint256[](coll3Len);

        uint256 n = 0;
        for (uint256 i; i < coll1Len; ++i) {
            uint256 tokenIndex = ds.whitelist.getIndex(_coll1.tokens[i]);
            if (_coll1.amounts[i] != 0) {
                n++;
                coll3.amounts[tokenIndex] = _coll1.amounts[i];
            }
        }

        for (uint256 i; i < coll2Len; ++i) {
            uint256 tokenIndex = ds.whitelist.getIndex(_coll2.tokens[i]);
            if (_coll2.amounts[i] != 0) {
                if (coll3.amounts[tokenIndex] == 0) {
                    n++;
                }
                coll3.amounts[tokenIndex] += (_coll2.amounts[i]);
            }
        }

        address[] memory sumTokens = new address[](n);
        uint256[] memory sumAmounts = new uint256[](n);
        uint256 j;

        // should only find n amounts over 0
        for (uint256 i; i < coll3Len; ++i) {
            if (coll3.amounts[i] != 0) {
                sumTokens[j] = coll3.tokens[i];
                sumAmounts[j] = coll3.amounts[i];
                j++;
            }
        }
        finalColls.tokens = sumTokens;
        finalColls.amounts = sumAmounts;
    }

    // gets the sum of coll1 with tokens and amounts
    function _sumColls(
        LibMojoDiamond.newColls memory _coll1,
        address[] calldata tokens,
        uint256[] calldata amounts
    ) internal view returns (LibMojoDiamond.newColls memory) {
        LibMojoDiamond.newColls memory coll2 = LibMojoDiamond.newColls(tokens, amounts);
        return _sumColls(_coll1, coll2);
    }

    function _sumColls(
        address[] calldata tokens1,
        uint256[] calldata amounts1,
        address[] calldata tokens2,
        uint256[] calldata amounts2
    ) internal view returns (LibMojoDiamond.newColls memory) {
        LibMojoDiamond.newColls memory coll1 = LibMojoDiamond.newColls(tokens1, amounts1);
        return _sumColls(coll1, tokens2, amounts2);
    }

    // Function for summing colls when coll1 includes all the tokens in the whitelist
    // Used in active, default, stability, and surplus pools
    // assumes _coll1.tokens = all whitelisted tokens
    function _leftSumColls(
        LibMojoDiamond.newColls memory _coll1,
        address[] calldata _tokens,
        uint256[] calldata _amounts
    ) internal view returns (uint256[] memory) {
        uint256[] memory sumAmounts = _getArrayCopy(_coll1.amounts);

        LibMojoDiamond.DiamondStorage storage ds = LibMojoDiamond
            .diamondStorage();

        uint256 coll1Len = _tokens.length;
        // assumes that sumAmounts length = whitelist tokens length.
        for (uint256 i; i < coll1Len; ++i) {
            uint256 tokenIndex = ds.whitelist.getIndex(_tokens[i]);
            sumAmounts[tokenIndex] += _amounts[i];
        }

        return sumAmounts;
    }

    // Function for summing colls when one list is all tokens. Used in active, default, stability, and surplus pools
    function _leftSubColls(
        LibMojoDiamond.newColls calldata _coll1,
        address[] calldata _subTokens,
        uint256[] calldata _subAmounts
    ) internal view returns (uint256[] memory) {
        uint256[] memory diffAmounts = _getArrayCopy(_coll1.amounts);

        LibMojoDiamond.DiamondStorage storage ds = LibMojoDiamond
            .diamondStorage();

        //assumes that coll1.tokens = whitelist tokens. Keeps all of coll1's tokens, and subtracts coll2's amounts
        uint256 subTokensLen = _subTokens.length;
        for (uint256 i; i < subTokensLen; ++i) {
            uint256 tokenIndex = ds.whitelist.getIndex(_subTokens[i]);
            diffAmounts[tokenIndex] -= (_subAmounts[i]);
        }
        return diffAmounts;
    }

    // Returns _coll1 minus _tokens and _amounts
    // will error if _tokens include a token not in _coll1.tokens
    function _subColls(
        LibMojoDiamond.newColls calldata _coll1,
        address[] calldata _tokens,
        uint256[] calldata _amounts
    ) internal view returns (LibMojoDiamond.newColls memory finalColls) {
        uint256 coll1Len = _coll1.tokens.length;
        uint256 tokensLen = _tokens.length;
        require(tokensLen == _amounts.length, "SubColls invalid input");

        LibMojoDiamond.DiamondStorage storage ds = LibMojoDiamond
            .diamondStorage();

        LibMojoDiamond.newColls memory coll3;
        coll3.tokens = ds.whitelist.getValidCollateral();
        uint256 coll3Len = coll3.tokens.length;
        coll3.amounts = new uint256[](coll3Len);
        uint256 n = 0;
        uint256 tokenIndex;
        uint256 i;
        for (; i < coll1Len; ++i) {
            if (_coll1.amounts[i] != 0) {
                tokenIndex = ds.whitelist.getIndex(_coll1.tokens[i]);
                coll3.amounts[tokenIndex] = _coll1.amounts[i];
                n++;
            }
        }
        uint256 thisAmounts;
        tokenIndex = 0;
        i = 0;
        for (; i < tokensLen; ++i) {
            tokenIndex = ds.whitelist.getIndex(_tokens[i]);
            thisAmounts = _amounts[i];
            require(coll3.amounts[tokenIndex] >= thisAmounts, "illegal sub");
            coll3.amounts[tokenIndex] += thisAmounts;
            if (coll3.amounts[tokenIndex] == 0) {
                n--;
            }
        }

        address[] memory diffTokens = new address[](n);
        uint256[] memory diffAmounts = new uint256[](n);

        if (n != 0) {
            uint256 j;
            i = 0;
            for (; i < coll3Len; ++i) {
                if (coll3.amounts[i] != 0) {
                    diffTokens[j] = coll3.tokens[i];
                    diffAmounts[j] = coll3.amounts[i];
                    ++j;
                }
            }
        }
        finalColls.tokens = diffTokens;
        finalColls.amounts = diffAmounts;
        // returns finalColls;
    }

    function _getArrayCopy(uint256[] memory _arr)
        internal
        pure
        returns (uint256[] memory)
    {
        uint256 arrLen = _arr.length;
        uint256[] memory copy = new uint256[](arrLen);
        for (uint256 i; i < arrLen; ++i) {
            copy[i] = _arr[i];
        }
        return copy;
    }
}
