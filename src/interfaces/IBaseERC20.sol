// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

interface IBaseERC20 {
    error MaxSupplyExceeded(uint256 supplyAfterMint);
    error InvalidOwner(address _caller);

    function owner() external view returns (address);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function maxSupply() external view returns (uint256);
    function transferOwnership(address newOwner) external;
    function transfer(address to, uint256 value) external returns (bool);

    function allowance(address owner_, address spender) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function burn(uint256 amount) external;
    function burn(address account, uint256 amount) external;
    function burnFrom(address account, uint256 value) external;
    function mint(address account, uint256 amount) external;

    function grantMintAndBurnRoles(address burnAndMinter) external;
    function grantMintRole(address minter) external;
    function grantBurnRole(address burner) external;
    function revokeMintRole(address minter) external;
    function revokeBurnRole(address burner) external;
    function getMinters() external view returns (address[] memory);
    function getBurners() external view returns (address[] memory);
    function isMinter(address minter) external view returns (bool);
    function isBurner(address burner) external view returns (bool);
}
