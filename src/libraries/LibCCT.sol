// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {LibDiamond} from "../libraries/LibDiamond.sol";
import {LibERC20} from "../libraries/LibERC20.sol";

import {IERC677} from "../interfaces/IERC677.sol";
import {IERC677Receiver} from "../interfaces/IERC677Receiver.sol";

library LibCCT {
    using EnumerableSet for EnumerableSet.AddressSet;

    struct CCTStorage {
        /// @dev the allowed minter&burner addresses
        EnumerableSet.AddressSet _cctOperators;
    }

    bytes32 constant CCT_POSITION = keccak256("cct.storage");

    event CCTOperatorSet(address indexed newOperator, address indexed setBy);
    event CCTOperatorRemoved(address indexed removedOperator, address indexed removedBy);

    error MaxSupplyExceeded(uint256 supplyAfterMint);
    error NotCCTOperator(address sender);

    function cctStorage() internal pure returns (CCTStorage storage storageStruct) {
        bytes32 position = CCT_POSITION;
        assembly {
            storageStruct.slot := position
        }
    }

    // @notice Grants cctOperator permission to the given address.
    function addCCTOperator(address newOperator) internal {
        CCTStorage storage ccts = cctStorage();

        if (ccts._cctOperators.add(newOperator)) {
            emit CCTOperatorSet(newOperator, msg.sender);
        }
    }

    // @notice Removes cctOperator permissions from the given address.
    function removeCCTOperator(address operatorToRemove) internal {
        CCTStorage storage ccts = cctStorage();

        if (ccts._cctOperators.remove(operatorToRemove)) {
            emit CCTOperatorRemoved(operatorToRemove, msg.sender);
        }
    }

    // @inheritdoc IBurnMintERC20
    // @dev Uses OZ ERC20 _mint to disallow minting to address(0).
    // @dev Disallows minting to address(this)
    // @dev Increases the total supply.
    function mint(address account, uint256 amount) internal {
        if (LibERC20.maxSupply() != 0 && LibERC20.totalSupply() + amount > LibERC20.maxSupply()) {
            revert MaxSupplyExceeded(LibERC20.totalSupply() + amount);
        }

        LibERC20._mint(account, amount);
    }

    // @dev Decreases the total supply.
    function burn(uint256 amount) internal {
        LibERC20._burn(LibERC20._msgSender(), amount);
    }

    function burnFrom(address account, uint256 value) internal {
        LibERC20._spendAllowance(account, LibERC20._msgSender(), value);
        LibERC20._burn(account, value);
    }

    // @inheritdoc IERC677
    function transferAndCall(address to, uint256 amount, bytes memory data) internal returns (bool success) {
        LibERC20.transfer(to, amount);
        emit IERC677.Transfer(msg.sender, to, amount, data);
        if (to.code.length > 0) {
            IERC677Receiver(to).onTokenTransfer(msg.sender, amount, data);
        }
        return true;
    }

    // @notice Returns all permissioned cctOperators
    function getCCTOperators() internal view returns (address[] memory) {
        return cctStorage()._cctOperators.values();
    }

    // @notice Checks whether a given address is a cctOperator for this token.
    function isCCTOperator(address operator) internal view returns (bool) {
        return cctStorage()._cctOperators.contains(operator);
    }

    function enforceIsCCTOperator() internal view {
        require(isCCTOperator(msg.sender), NotCCTOperator(msg.sender));
    }
}
