// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {LibDiamond} from "../libraries/LibDiamond.sol";
import {LibCCT} from "../libraries/LibCCT.sol";
import {IERC677} from "../interfaces/IERC677.sol";

contract CCTFacet is IERC677 {
    modifier onlyOwner() {
        LibDiamond.enforceIsOwner();
        _;
    }

    modifier onlyOperator() {
        LibCCT.enforceIsCCTOperator();
        _;
    }

    constructor() {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        ds.supportedInterfaces[type(IERC677).interfaceId] = true;
    }

    function addCCTOperator(address newOperator) external onlyOwner {
        LibCCT.addCCTOperator(newOperator);
    }

    function removeCCTOperator(address operatorToRemove) external onlyOwner {
        LibCCT.removeCCTOperator(operatorToRemove);
    }

    function mint(address account, uint256 amount) external onlyOperator {
        LibCCT.mint(account, amount);
    }

    function burn(uint256 amount) external onlyOperator {
        LibCCT.burn(amount);
    }

    function burnFrom(address account, uint256 value) external onlyOperator {
        LibCCT.burnFrom(account, value);
    }

    function transferAndCall(address to, uint256 amount, bytes memory data) external returns (bool success) {
        return LibCCT.transferAndCall(to, amount, data);
    }

    function getCCTOperators() external view returns (address[] memory) {
        return LibCCT.getCCTOperators();
    }

    function isCCTOperator(address operator) external view returns (bool) {
        return LibCCT.isCCTOperator(operator);
    }
}
