// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {LibRoles} from "../libraries/LibRoles.sol";
import {LibDiamond} from "../libraries/LibDiamond.sol";

contract RolesFacet {
    using EnumerableSet for EnumerableSet.AddressSet;

    event MintAccessGranted(address indexed minter);
    event BurnAccessGranted(address indexed burner);
    event MintAccessRevoked(address indexed minter);
    event BurnAccessRevoked(address indexed burner);

    error InvalidOwner(address _caller);

    modifier onlyOwner() {
        require(msg.sender == LibDiamond.contractOwner(), InvalidOwner(msg.sender));
        _;
    }

    // @notice grants both mint and burn roles to `burnAndMinter`.
    // @dev calls public functions so this function does not require
    // access controls. This is handled in the inner functions.
    function grantMintAndBurnRoles(address burnAndMinter) external {
        grantMintRole(burnAndMinter);
        grantBurnRole(burnAndMinter);
    }

    // @notice Grants mint role to the given address.
    // @dev only the owner can call this function.
    function grantMintRole(address minter) public onlyOwner {
        LibRoles.RolesStorage storage roless = LibRoles.rolesStorage();
        if (roless._minters.add(minter)) {
            emit MintAccessGranted(minter);
        }
    }

    // @notice Grants burn role to the given address.
    // @dev only the owner can call this function.
    function grantBurnRole(address burner) public onlyOwner {
        LibRoles.RolesStorage storage roless = LibRoles.rolesStorage();
        if (roless._burners.add(burner)) {
            emit BurnAccessGranted(burner);
        }
    }

    // @notice Revokes mint role for the given address.
    // @dev only the owner can call this function.
    function revokeMintRole(address minter) public onlyOwner {
        LibRoles.RolesStorage storage roless = LibRoles.rolesStorage();
        if (roless._minters.remove(minter)) {
            emit MintAccessRevoked(minter);
        }
    }

    // @notice Revokes burn role from the given address.
    // @dev only the owner can call this function
    function revokeBurnRole(address burner) public onlyOwner {
        LibRoles.RolesStorage storage roless = LibRoles.rolesStorage();
        if (roless._burners.remove(burner)) {
            emit BurnAccessRevoked(burner);
        }
    }

    // @notice Returns all permissioned minters
    function getMinters() public view returns (address[] memory) {
        return LibRoles.getMinters();
    }

    // @notice Returns all permissioned burners
    function getBurners() public view returns (address[] memory) {
        return LibRoles.getBurners();
    }

    // @notice Checks whether a given address is a minter for this token.
    // @return true if the address is allowed to mint.
    function isMinter(address minter) public view returns (bool) {
        return LibRoles.isMinter(minter);
    }

    // @notice Checks whether a given address is a burner for this token.
    // @return true if the address is allowed to burn.
    function isBurner(address burner) public view returns (bool) {
        return LibRoles.isBurner(burner);
    }
}
