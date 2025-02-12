// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {stdError} from "forge-std/StdError.sol";
import {IERC20Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";

import {DiamondInit} from "src/upgradeInitializers/DiamondInit.sol";
import {DiamondLoupeFacet} from "src/facets/DiamondLoupeFacet.sol";
import {DiamondCutFacet} from "src/facets/DiamondCutFacet.sol";
import {DiamondERC20STV3} from "src/DiamondERC20STV3.sol";
import {RolesFacet} from "src/facets/RolesFacet.sol";
import {CCIPFacet} from "src/facets/CCIPFacet.sol";
import {TransferValidationFacet} from "src/facets/TransferValidationFacet.sol";

import {IDiamond} from "src/interfaces/IDiamond.sol";
import {IBaseERC20} from "src/interfaces/IBaseERC20.sol";
import {LibRoles} from "src/libraries/LibRoles.sol";

contract BaseERC20Test is Test {
    bytes4[] sig;
    IDiamond.FacetCut[] facetCuts;

    string name = "TestDiamond V1.1";
    string symbol = "TDV11";
    uint8 decimals = 18;
    uint256 maxSupply = 100_000_000e18;
    address foundryDeployer = 0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38;

    DiamondInit diamondInit;
    DiamondCutFacet diamondCutFacet;
    DiamondLoupeFacet diamondLoupeFacet;
    DiamondERC20STV3 baseERC20;
    CCIPFacet cCIPFacet;
    RolesFacet rolesFacet;
    TransferValidationFacet transferValidationFacet;

    IBaseERC20 token;

    function cutFacetsPush(address facetAddress) internal {
        facetCuts.push(
            IDiamond.FacetCut({facetAddress: facetAddress, action: IDiamond.FacetCutAction.Add, functionSelectors: sig})
        );
    }

    function beforeTestSetup(bytes4 testSelector) public pure returns (bytes[] memory beforeTestCalldata) {
        if (testSelector == this.test_OwnerRevokesMintRole.selector) {
            beforeTestCalldata = new bytes[](1);
            beforeTestCalldata[0] = abi.encodePacked(this.test_OwnerGrantsMintRole.selector);
        }

        if (testSelector == this.test_OwnerRevokesBurnRole.selector) {
            beforeTestCalldata = new bytes[](1);
            beforeTestCalldata[0] = abi.encodePacked(this.test_OwnerGrantsBurnRole.selector);
        }

        if (testSelector == this.test_PositiveMintFlow.selector) {
            beforeTestCalldata = new bytes[](1);
            beforeTestCalldata[0] = abi.encodePacked(this.test_OwnerGrantsMintRole.selector);
        }

        if (testSelector == this.test_PositiveBurnFlow.selector) {
            beforeTestCalldata = new bytes[](1);
            beforeTestCalldata[0] = abi.encodePacked(this.test_OwnerGrantsMintAndBurnRoles.selector);
        }
    }

    function setUp() public {
        diamondInit = new DiamondInit();

        diamondCutFacet = new DiamondCutFacet();
        sig.push(diamondCutFacet.diamondCut.selector);

        cutFacetsPush(address(diamondCutFacet));

        sig.pop();

        diamondLoupeFacet = new DiamondLoupeFacet();
        sig.push(diamondLoupeFacet.facets.selector);
        sig.push(diamondLoupeFacet.facetFunctionSelectors.selector);
        sig.push(diamondLoupeFacet.facetAddresses.selector);
        sig.push(diamondLoupeFacet.facetAddress.selector);
        sig.push(diamondLoupeFacet.supportsInterface.selector);

        cutFacetsPush(address(diamondLoupeFacet));

        uint256 len = sig.length;
        for (uint256 i = 0; i < len; i++) {
            sig.pop();
        }

        cCIPFacet = new CCIPFacet();
        sig.push(bytes4(keccak256("burn(uint256)")));
        sig.push(bytes4(keccak256("burn(address,uint256)")));
        sig.push(cCIPFacet.burnFrom.selector);
        sig.push(cCIPFacet.mint.selector);
        sig.push(cCIPFacet.transferAndCall.selector);

        cutFacetsPush(address(cCIPFacet));

        uint256 len1 = sig.length;
        for (uint256 i = 0; i < len1; i++) {
            sig.pop();
        }

        rolesFacet = new RolesFacet();
        sig.push(rolesFacet.grantMintAndBurnRoles.selector);
        sig.push(rolesFacet.grantMintRole.selector);
        sig.push(rolesFacet.grantBurnRole.selector);
        sig.push(rolesFacet.revokeMintRole.selector);
        sig.push(rolesFacet.revokeBurnRole.selector);
        sig.push(rolesFacet.getMinters.selector);
        sig.push(rolesFacet.getBurners.selector);
        sig.push(rolesFacet.isMinter.selector);
        sig.push(rolesFacet.isBurner.selector);

        cutFacetsPush(address(rolesFacet));

        uint256 len2 = sig.length;
        for (uint256 i = 0; i < len2; i++) {
            sig.pop();
        }

        transferValidationFacet = new TransferValidationFacet();
        sig.push(transferValidationFacet.beforeUpdateValidation.selector);
        sig.push(transferValidationFacet.afterUpdateValidation.selector);

        cutFacetsPush(address(transferValidationFacet));

        uint256 len3 = sig.length;
        for (uint256 i = 0; i < len3; i++) {
            sig.pop();
        }

        bytes memory functionCall =
            abi.encodeWithSignature("init(string,string,uint8,uint256)", name, symbol, decimals, maxSupply);

        DiamondERC20STV3.DiamondArgs memory diamondArgs =
            DiamondERC20STV3.DiamondArgs({owner: msg.sender, init: address(diamondInit), initCalldata: functionCall});

        baseERC20 = new DiamondERC20STV3(facetCuts, diamondArgs);

        sig.push(baseERC20.owner.selector);
        sig.push(baseERC20.name.selector);
        sig.push(baseERC20.symbol.selector);
        sig.push(baseERC20.decimals.selector);
        sig.push(baseERC20.totalSupply.selector);
        sig.push(baseERC20.balanceOf.selector);
        sig.push(baseERC20.maxSupply.selector);
        sig.push(baseERC20.transferOwnership.selector);
        sig.push(baseERC20.transfer.selector);
        sig.push(baseERC20.allowance.selector);
        sig.push(baseERC20.approve.selector);
        sig.push(baseERC20.transferFrom.selector);

        cutFacetsPush(address(baseERC20));

        uint256 len4 = sig.length;
        for (uint256 i = 0; i < len4; i++) {
            sig.pop();
        }

        token = IBaseERC20(address(baseERC20));
        console.log("New ERC20 Token deployed to", address(baseERC20));
    }

    function test_OwnerWasSet() public view {
        assertEq(baseERC20.owner(), foundryDeployer);
    }

    function test_NameWasSet() public view {
        assertEq(baseERC20.name(), name);
    }

    function test_SymbolWasSet() public view {
        assertEq(baseERC20.symbol(), symbol);
    }

    function test_DecimalsWasSet() public view {
        assertEq(baseERC20.decimals(), decimals);
    }

    function test_MaxSupplyWasSet() public view {
        assertEq(baseERC20.maxSupply(), maxSupply);
    }

    function test_DefaultTotalSupplyIsZero() public view {
        assertEq(baseERC20.totalSupply(), 0);
    }

    function test_PositiveTransferOwnership() public {
        vm.startPrank(foundryDeployer);
        assertEq(token.owner(), foundryDeployer);

        address newOwner = makeAddr("newOwner");
        token.transferOwnership(newOwner);
        assertEq(token.owner(), newOwner);

        vm.stopPrank();
    }

    function test_RevertTransferOwnershipIf_NotOwner() public {
        vm.expectPartialRevert(IBaseERC20.InvalidOwner.selector);
        address newOwner = makeAddr("newOwner");
        token.transferOwnership(newOwner);
    }

    function test_OwnerGrantsMintRole() public {
        vm.prank(foundryDeployer);
        token.grantMintRole(foundryDeployer);
        assertTrue(token.isMinter(foundryDeployer));
    }

    function test_OwnerRevokesMintRole() public {
        vm.prank(foundryDeployer);
        token.revokeMintRole(foundryDeployer);
        assertFalse(token.isMinter(foundryDeployer));
    }

    function test_OwnerGrantsBurnRole() public {
        vm.prank(foundryDeployer);
        token.grantBurnRole(foundryDeployer);
        assertTrue(token.isBurner(foundryDeployer));
    }

    function test_OwnerRevokesBurnRole() public {
        vm.prank(foundryDeployer);
        token.revokeBurnRole(foundryDeployer);
        assertFalse(token.isBurner(foundryDeployer));
    }

    function test_OwnerGrantsMintAndBurnRoles() public {
        vm.prank(foundryDeployer);
        token.grantMintAndBurnRoles(foundryDeployer);
        assertTrue(token.isMinter(foundryDeployer));
        assertTrue(token.isBurner(foundryDeployer));
    }

    function test_PositiveMintFlow() public {
        vm.prank(foundryDeployer);
        token.mint(foundryDeployer, 20e18);
    }

    function test_PositiveBurnFlow() public {
        vm.startPrank(foundryDeployer);
        token.mint(foundryDeployer, 20e18);
        assertEq(token.balanceOf(foundryDeployer), 20e18);

        token.burn(15e18);
        assertEq(token.balanceOf(foundryDeployer), 5e18);

        vm.stopPrank();
    }

    function test_RevertMintIf_NotMinter() public {
        vm.expectPartialRevert(LibRoles.SenderNotMinter.selector);
        token.mint(foundryDeployer, 20e18);
    }

    function test_RevertBurnIf_NotBurner() public {
        vm.startPrank(foundryDeployer);
        token.grantMintRole(foundryDeployer);

        token.mint(foundryDeployer, 20e18);
        assertEq(token.balanceOf(foundryDeployer), 20e18);

        vm.expectPartialRevert(LibRoles.SenderNotBurner.selector);
        token.burn(20e18);

        vm.stopPrank();
    }

    function test_TotalSupplyChanges() public {
        vm.startPrank(foundryDeployer);
        token.grantMintAndBurnRoles(foundryDeployer);

        token.mint(foundryDeployer, 1000e18);
        assertEq(token.totalSupply(), 1000e18);

        token.burn(150e18);
        assertEq(token.totalSupply(), 850e18);

        vm.stopPrank();
    }

    function test_RevertIf_MaxSupplyExceeded() public {
        vm.startPrank(foundryDeployer);
        token.grantMintRole(foundryDeployer);

        vm.expectPartialRevert(IBaseERC20.MaxSupplyExceeded.selector);
        token.mint(foundryDeployer, maxSupply + 1);

        vm.stopPrank();
    }

    function test_Approve() public {
        vm.prank(foundryDeployer);
        address user = makeAddr("user");

        token.approve(user, 100e18);
        assertEq(token.allowance(foundryDeployer, user), 100e18);
    }

    function test_PositiveTransferFlow() public {
        vm.startPrank(foundryDeployer);
        token.grantMintRole(foundryDeployer);
        address user = makeAddr("user");

        token.mint(foundryDeployer, 100e18);
        token.transfer(user, 30e18);

        assertEq(token.balanceOf(foundryDeployer), 70e18);
        assertEq(token.balanceOf(user), 30e18);
    }

    function test_RevertTransferIf_FromZeroAddress() public {
        vm.prank(address(0));
        vm.expectPartialRevert(IERC20Errors.ERC20InvalidSender.selector);
        token.transfer(foundryDeployer, 100e18);
    }

    function test_RevertTransferIf_ToZeroAddress() public {
        vm.prank(foundryDeployer);
        vm.expectPartialRevert(IERC20Errors.ERC20InvalidReceiver.selector);
        token.transfer(address(0), 100e18);
    }

    function test_RevertTransferIf_InsufficientBalance() public {
        vm.startPrank(foundryDeployer);
        token.grantMintRole(foundryDeployer);
        token.mint(foundryDeployer, 100e18);

        address to = makeAddr("to");
        vm.expectPartialRevert(IERC20Errors.ERC20InsufficientBalance.selector);
        token.transfer(to, 101e18);

        vm.stopPrank();
    }

    function test_PositiveTransferFromFlow() public {
        address user = makeAddr("user");
        vm.prank(user);
        token.approve(foundryDeployer, 30e18);
        assertEq(token.allowance(user, foundryDeployer), 30e18);

        vm.startPrank(foundryDeployer);
        token.grantMintRole(foundryDeployer);

        token.mint(user, 100e18);
        token.transferFrom(user, foundryDeployer, 30e18);

        assertEq(token.balanceOf(foundryDeployer), 30e18);
        assertEq(token.balanceOf(user), 70e18);
        assertEq(token.allowance(user, foundryDeployer), 0);

        vm.stopPrank();
    }

    function test_RevertTransferFromIf_InsufficientAllowance() public {
        address user = makeAddr("user");
        vm.prank(user);
        token.approve(foundryDeployer, 30e18);
        assertEq(token.allowance(user, foundryDeployer), 30e18);

        vm.startPrank(foundryDeployer);
        token.grantMintRole(foundryDeployer);

        token.mint(user, 100e18);

        vm.expectPartialRevert(IERC20Errors.ERC20InsufficientAllowance.selector);
        token.transferFrom(user, foundryDeployer, 31e18);

        vm.stopPrank();
    }

    function test_MaximumAllowanceDoesntUpdate() public {
        address user = makeAddr("user");
        vm.prank(user);
        token.approve(foundryDeployer, type(uint256).max);
        assertEq(token.allowance(user, foundryDeployer), type(uint256).max);

        vm.startPrank(foundryDeployer);
        token.grantMintRole(foundryDeployer);

        token.mint(user, 100e18);
        token.transferFrom(user, foundryDeployer, 30e18);

        assertEq(token.balanceOf(foundryDeployer), 30e18);
        assertEq(token.balanceOf(user), 70e18);
        assertEq(token.allowance(user, foundryDeployer), type(uint256).max);

        vm.stopPrank();
    }
}
