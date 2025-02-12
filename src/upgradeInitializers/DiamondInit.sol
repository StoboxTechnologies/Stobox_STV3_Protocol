// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {LibDiamond} from "../libraries/LibDiamond.sol";
import {LibERC20} from "../libraries/LibERC20.sol";
import {IDiamondLoupe} from "../interfaces/IDiamondLoupe.sol";
import {IDiamondCut} from "../interfaces/IDiamondCut.sol";
import {IERC173} from "../interfaces/IERC173.sol";
import {IERC165} from "../interfaces/IERC165.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DiamondInit {
    // You can add parameters to this function in order to pass in
    // data to set your own state variables

    function init(string memory name, string memory symbol, uint8 decimals, uint256 maxSupply) external {
        // adding ERC165 data
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        ds.supportedInterfaces[type(IERC165).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondCut).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondLoupe).interfaceId] = true;
        ds.supportedInterfaces[type(IERC173).interfaceId] = true;
        ds.supportedInterfaces[type(IERC20).interfaceId] = true;

        // add your own state variables
        LibERC20.ERC20Storage storage erc20s = LibERC20.erc20Storage();
        erc20s._name = name;
        erc20s._symbol = symbol;
        erc20s._decimals = decimals;
        erc20s._maxSupply = maxSupply;

        // EIP-2535 specifies that the `diamondCut` function takes two optional
        // arguments: address _init and bytes calldata _calldata
        // These arguments are used to execute an arbitrary function using delegatecall
        // in order to set state variables in the diamond during deployment or an upgrade
        // More info here: https://eips.ethereum.org/EIPS/eip-2535#diamond-interface
    }
}
