// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

interface IBaseERC20 {
    error MaxSupplyExceeded(uint256 supplyAfterMint);
    error NotDeployer(address _user, address _deployer);
    error ZeroAddressNotAllowed();
    error NotCCTOperator(address sender);

    function transfer(address to, uint256 value) external;
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function setDeployer(address newDeployer) external;
    function transferOwnership(address newOwner) external;
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function maxSupply() external view returns (uint256);
    function allowance(address owner_, address spender) external view returns (uint256);
    function deployer() external view returns (address);
    function owner() external view returns (address);

    function addCCTOperator(address newOperator) external;
    function removeCCTOperator(address operatorToRemove) external;
    function mint(address account, uint256 amount) external;
    function burn(uint256 amount) external;
    function burnFrom(address account, uint256 value) external;
    function transferAndCall(address to, uint256 amount, bytes memory data) external returns (bool success);
    function getCCTOperators() external view returns (address[] memory);
    function isCCTOperator(address operator) external view returns (bool);
}
