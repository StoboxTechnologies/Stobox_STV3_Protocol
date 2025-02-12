// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

library LibRoles {
    using EnumerableSet for EnumerableSet.AddressSet;

    bytes32 constant ROLES_POSITION = keccak256("roles.storage");

    struct RolesStorage {
        /// @dev the allowed minter addresses
        EnumerableSet.AddressSet _minters;
        /// @dev the allowed burner addresses
        EnumerableSet.AddressSet _burners;
    }

    error SenderNotMinter(address sender);
    error SenderNotBurner(address sender);

    function rolesStorage() internal pure returns (RolesStorage storage storageStruct) {
        bytes32 position = ROLES_POSITION;
        assembly {
            storageStruct.slot := position
        }
    }

    // @notice Returns all permissioned minters
    function getMinters() internal view returns (address[] memory) {
        return rolesStorage()._minters.values();
    }

    // @notice Returns all permissioned burners
    function getBurners() internal view returns (address[] memory) {
        return rolesStorage()._burners.values();
    }

    // @notice Checks whether a given address is a minter for this token.
    // @return true if the address is allowed to mint.
    function isMinter(address minter) internal view returns (bool) {
        return rolesStorage()._minters.contains(minter);
    }

    // @notice Checks whether a given address is a burner for this token.
    // @return true if the address is allowed to burn.
    function isBurner(address burner) internal view returns (bool) {
        return rolesStorage()._burners.contains(burner);
    }

    function ifNotMinterRevert() internal view {
        require(isMinter(msg.sender), SenderNotMinter(msg.sender));
    }

    function ifNotBurnerRevert() internal view {
        require(isBurner(msg.sender), SenderNotBurner(msg.sender));
    }
}
