// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

interface ITransferValidation {
    function beforeUpdateValidation(address from, address to, uint256 value) external;

    function afterUpdateValidation(address from, address to, uint256 value) external;
}
