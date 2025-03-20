// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IERC173} from "./interfaces/IERC173.sol";
import {IDiamondCut} from "./interfaces/IDiamondCut.sol";
import {LibDiamond} from "./libraries/LibDiamond.sol";
import {LibERC20} from "./libraries/LibERC20.sol";

contract StoboxProtocolSTV3 is IERC20 {
    // This is used in diamond constructor
    // more arguments are added to this struct
    // this avoids stack too deep errors
    struct DiamondArgs {
        address deployer;
        address owner;
        address init;
        bytes initCalldata;
    }

    // When no function exists for function called
    error FunctionNotFound(bytes4 _functionSelector);
    error ZeroAddressIsNotAllowed();

    modifier onlyDeployer() {
        LibDiamond.enforceIsDeployer();
        _;
    }

    constructor(IDiamondCut.FacetCut[] memory _diamondCut, DiamondArgs memory _args) payable {
        LibDiamond.setDeployer(_args.deployer);
        LibDiamond.transferOwnership(_args.owner);
        LibDiamond.diamondCut(_diamondCut, _args.init, _args.initCalldata);
    }

    receive() external payable {}

    // Find facet for function that is called and execute the
    // function if a facet is found and return any value.
    fallback() external payable {
        LibDiamond.DiamondStorage storage ds;
        bytes32 position = LibDiamond.DIAMOND_STORAGE_POSITION;
        // get diamond storage
        assembly {
            ds.slot := position
        }
        // get facet from function selector
        address facet = ds.facetAddressAndSelectorPosition[msg.sig].facetAddress;
        if (facet == address(0)) {
            revert FunctionNotFound(msg.sig);
        }
        // Execute external function from facet using delegatecall and return any value.
        assembly {
            // copy function selector and any arguments
            calldatacopy(0, 0, calldatasize())
            // execute function call using the facet
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            // get any return value
            returndatacopy(0, 0, returndatasize())
            // return any return value or error back to the caller
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    // Requirements:
    // - `to` cannot be the zero address.
    // - the caller must have a balance of at least `value`.
    function transfer(address to, uint256 value) external returns (bool) {
        return LibERC20.transfer(to, value);
    }

    // NOTE: If `value` is the maximum `uint256`, the allowance is not updated on
    // `transferFrom`. This is semantically equivalent to an infinite approval.
    // Requirements:
    // - `spender` cannot be the zero address.
    function approve(address spender, uint256 value) external returns (bool) {
        return LibERC20.approve(spender, value);
    }

    // Skips emitting an {Approval} event indicating an allowance update. This is not required by the ERC.
    // NOTE: Does not update the allowance if the current allowance
    // is the maximum `uint256`.
    // Requirements:
    // - `from` and `to` cannot be the zero address.
    // - `from` must have a balance of at least `value`.
    // - the caller must have allowance for ``from``'s tokens of at least `value`
    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        return LibERC20.transferFrom(from, to, value);
    }

    // @dev Set the address of the new deployer of the contract
    // Can only be called by the current deployer.
    // @param newDeployer The address of the new deployer of the contract
    function setDeployer(address newDeployer) external onlyDeployer {
        require(newDeployer != address(0), ZeroAddressIsNotAllowed());
        LibDiamond.setDeployer(newDeployer);
    }

    // @dev Set the address of the new owner of the contract
    // Can only be called by the current deployer.
    // @param newOwner The address of the new owner of the contract
    function transferOwnership(address newOwner) external onlyDeployer {
        require(newOwner != address(0), ZeroAddressIsNotAllowed());
        LibDiamond.transferOwnership(newOwner);
    }

    // @dev Returns the name of the token.
    function name() external view returns (string memory) {
        return LibERC20.name();
    }

    // @dev Returns the symbol of the token, usually a shorter version of the
    function symbol() external view returns (string memory) {
        return LibERC20.symbol();
    }

    // @dev Returns the number of decimals used to get its user representation.
    function decimals() external view returns (uint8) {
        return LibERC20.decimals();
    }

    // @dev See {IERC20-totalSupply}.
    function totalSupply() external view returns (uint256) {
        return LibERC20.totalSupply();
    }

    // @dev See {IERC20-balanceOf}.
    function balanceOf(address account) external view returns (uint256) {
        return LibERC20.balanceOf(account);
    }

    // @dev Returns the max supply of the token, 0 if unlimited.
    function maxSupply() external view returns (uint256) {
        return LibERC20.maxSupply();
    }

    function allowance(address owner_, address spender) external view returns (uint256) {
        return LibERC20.allowance(owner_, spender);
    }

    // @dev Get the address of the deployer
    function deployer() external view returns (address) {
        return LibDiamond.deployer();
    }

    // @dev Get the address of the owner
    function owner() external view returns (address) {
        return LibDiamond.owner();
    }
}
