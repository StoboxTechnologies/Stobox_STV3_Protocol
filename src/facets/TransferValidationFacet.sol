// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {LibDiamond} from "../libraries/LibDiamond.sol";

contract TransferValidationFacet {
    function beforeUpdateValidation(address from, address to, uint256 value) external {}

    function afterUpdateValidation(address from, address to, uint256 value) external {}
}
