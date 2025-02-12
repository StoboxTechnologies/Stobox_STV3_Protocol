// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {LibDiamond} from "../libraries/LibDiamond.sol";
import {LibRoles} from "../libraries/LibRoles.sol";
import {LibERC20} from "../libraries/LibERC20.sol";

import {IERC677} from "../interfaces/IERC677.sol";
import {IERC677Receiver} from "../interfaces/IERC677Receiver.sol";

contract CCIPFacet is IERC677 {
    error MaxSupplyExceeded(uint256 supplyAfterMint);

    // @notice Checks whether the msg.sender is a permissioned minter for this token
    // @dev Reverts with a SenderNotMinter if the check fails
    modifier onlyMinter() {
        LibRoles.ifNotMinterRevert();
        _;
    }

    // @notice Checks whether the msg.sender is a permissioned burner for this token
    // @dev Reverts with a SenderNotBurner if the check fails
    modifier onlyBurner() {
        LibRoles.ifNotBurnerRevert();
        _;
    }

    constructor() {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        ds.supportedInterfaces[type(IERC677).interfaceId] = true;
        ds.supportedInterfaces[type(IERC677Receiver).interfaceId] = true;
    }

    // @dev Decreases the total supply.
    function burn(uint256 amount) public onlyBurner {
        LibERC20._burn(LibERC20._msgSender(), amount);
    }

    // @dev Alias for BurnFrom for compatibility with the older naming convention.
    // @dev Uses burnFrom for all validation & logic.
    function burn(address account, uint256 amount) public {
        burnFrom(account, amount);
    }

    function burnFrom(address account, uint256 value) public onlyBurner {
        LibERC20._spendAllowance(account, LibERC20._msgSender(), value);
        LibERC20._burn(account, value);
    }

    // @inheritdoc IBurnMintERC20
    // @dev Uses OZ ERC20 _mint to disallow minting to address(0).
    // @dev Disallows minting to address(this)
    // @dev Increases the total supply.
    function mint(address account, uint256 amount) external onlyMinter {
        if (LibERC20.maxSupply() != 0 && LibERC20.totalSupply() + amount > LibERC20.maxSupply()) {
            revert MaxSupplyExceeded(LibERC20.totalSupply() + amount);
        }

        LibERC20._mint(account, amount);
    }

    // @inheritdoc IERC677
    function transferAndCall(address to, uint256 amount, bytes memory data) public returns (bool success) {
        LibERC20.transfer(to, amount);
        emit Transfer(msg.sender, to, amount, data);
        if (to.code.length > 0) {
            IERC677Receiver(to).onTokenTransfer(msg.sender, amount, data);
        }
        return true;
    }
}
