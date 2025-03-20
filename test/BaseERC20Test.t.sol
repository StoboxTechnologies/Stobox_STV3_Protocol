// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {stdError} from "forge-std/StdError.sol";
import {IERC20Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";

import {DiamondInit} from "src/upgradeInitializers/DiamondInit.sol";
import {DiamondLoupeFacet} from "src/facets/DiamondLoupeFacet.sol";
import {DiamondCutFacet} from "src/facets/DiamondCutFacet.sol";
import {StoboxProtocolSTV3} from "src/StoboxProtocolSTV3.sol";
import {CCTFacet} from "src/facets/CCTFacet.sol";
import {DefaultValidationFacet} from "src/facets/DefaultValidationFacet.sol";

import {IDiamond} from "src/interfaces/IDiamond.sol";
import {IBaseERC20} from "src/interfaces/IBaseERC20.sol";
import {ITransferValidation} from "src/interfaces/ITransferValidation.sol";

import {LibCCT} from "src/libraries/LibCCT.sol";
import {DeployDiamondLibrary} from "script/Deploy.s.sol";

contract BaseERC20Test is Test {
    bytes4[] sig;
    IDiamond.FacetCut[] facetCuts;

    bytes4[] sigIm;
    IDiamond.FacetCut[] facetCutsIm;

    string name = "TestDiamond V1.1.1";
    string symbol = "TDV111";
    uint8 decimals = 18;
    uint256 maxSupply = 100_000_000e18;
    address foundryDeployer = 0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496;
    //address foundryDeployer = 0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38;

    DiamondInit diamondInit;
    DiamondCutFacet diamondCutFacet;
    DiamondLoupeFacet diamondLoupeFacet;
    StoboxProtocolSTV3 baseERC20;
    CCTFacet cctFacet;
    DefaultValidationFacet defaultValidationFacet;

    IBaseERC20 token;
    ITransferValidation tokenValidation;

    function cutFacetsPush(address facetAddress) internal {
        facetCuts.push(
            IDiamond.FacetCut({facetAddress: facetAddress, action: IDiamond.FacetCutAction.Add, functionSelectors: sig})
        );
    }

    function beforeTestSetup(bytes4 testSelector) public pure returns (bytes[] memory beforeTestCalldata) {
        if (testSelector == this.test_DeployerRemoveCCTOperator.selector) {
            beforeTestCalldata = new bytes[](1);
            beforeTestCalldata[0] = abi.encodePacked(this.test_DeployerAddsCCTOperator.selector);
        }

        if (testSelector == this.test_PositiveMintFlow.selector) {
            beforeTestCalldata = new bytes[](1);
            beforeTestCalldata[0] = abi.encodePacked(this.test_DeployerAddsCCTOperator.selector);
        }

        if (testSelector == this.test_PositiveBurnFlow.selector) {
            beforeTestCalldata = new bytes[](1);
            beforeTestCalldata[0] = abi.encodePacked(this.test_DeployerAddsCCTOperator.selector);
        }

        if (testSelector == this.test_PositiveBurnFromFlow.selector) {
            beforeTestCalldata = new bytes[](1);
            beforeTestCalldata[0] = abi.encodePacked(this.test_DeployerAddsCCTOperator.selector);
        }

        if (testSelector == this.test_RevertBurnIf_NotCCTOperator.selector) {
            beforeTestCalldata = new bytes[](2);
            beforeTestCalldata[0] = abi.encodePacked(this.test_DeployerAddsCCTOperator.selector);
            beforeTestCalldata[1] = abi.encodePacked(this.test_PositiveMintFlow.selector);
        }

        if (testSelector == this.test_RevertBurnFromIf_NotCCTOperator.selector) {
            beforeTestCalldata = new bytes[](1);
            beforeTestCalldata[0] = abi.encodePacked(this.test_DeployerAddsCCTOperator.selector);
        }
    }

    function setUp() public {
        (baseERC20,,,,) = DeployDiamondLibrary.deployDiamond(
            foundryDeployer, foundryDeployer, name, symbol, decimals, maxSupply, sig, facetCuts, sigIm, facetCutsIm
        );

        token = IBaseERC20(address(baseERC20));
        tokenValidation = ITransferValidation(address(baseERC20));
    }

    function test_DeployerWasSet() public view {
        assertEq(baseERC20.deployer(), foundryDeployer);
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

    function test_PositiveSetDeployer() public {
        vm.startPrank(foundryDeployer);
        assertEq(token.deployer(), foundryDeployer);

        address newDeployer = makeAddr("newDeployer");
        token.setDeployer(newDeployer);
        assertEq(token.deployer(), newDeployer);

        vm.stopPrank();
    }

    function test_PositiveSetOwner() public {
        vm.startPrank(foundryDeployer);
        assertEq(token.owner(), foundryDeployer);

        address newOwner = makeAddr("newOwner");
        token.transferOwnership(newOwner);
        assertEq(token.owner(), newOwner);

        vm.stopPrank();
    }

    function test_RevertSetDeployerIf_NotDeployer() public {
        vm.expectPartialRevert(IBaseERC20.NotDeployer.selector);
        address newDeployer = makeAddr("newDeployer");
        vm.prank(newDeployer);
        token.setDeployer(newDeployer);
    }

    function test_RevertTransferOwnershipIf_NotDeployer() public {
        vm.expectPartialRevert(IBaseERC20.NotDeployer.selector);
        address newOwner = makeAddr("newOwner");
        vm.prank(newOwner);
        token.transferOwnership(newOwner);
    }

    function test_DeployerAddsCCTOperator() public {
        vm.prank(foundryDeployer);
        token.addCCTOperator(foundryDeployer);
        assertTrue(token.isCCTOperator(foundryDeployer));
    }

    function test_DeployerRemoveCCTOperator() public {
        vm.prank(foundryDeployer);
        token.removeCCTOperator(foundryDeployer);
        assertFalse(token.isCCTOperator(foundryDeployer));
    }

    function test_GetCCTOperators() public {
        address user = makeAddr("user");
        address[] memory operatorsList = new address[](2);
        operatorsList[0] = foundryDeployer;
        operatorsList[1] = user;

        vm.startPrank(foundryDeployer);
        token.addCCTOperator(foundryDeployer);
        token.addCCTOperator(user);

        assertEq(token.getCCTOperators()[0], operatorsList[0]);
        assertEq(token.getCCTOperators()[1], operatorsList[1]);
    }

    function test_PositiveMintFlow() public {
        vm.prank(foundryDeployer);
        token.mint(foundryDeployer, 20e18);

        assertEq(token.balanceOf(foundryDeployer), 20e18);
    }

    function test_PositiveBurnFlow() public {
        vm.startPrank(foundryDeployer);
        token.mint(foundryDeployer, 20e18);
        assertEq(token.balanceOf(foundryDeployer), 20e18);

        token.burn(15e18);
        assertEq(token.balanceOf(foundryDeployer), 5e18);

        vm.stopPrank();
    }

    function test_PositiveBurnFromFlow() public {
        address user = makeAddr("user");
        vm.prank(foundryDeployer);
        token.mint(user, 20e18);
        assertEq(token.balanceOf(user), 20e18);

        vm.prank(user);
        token.approve(foundryDeployer, 15e18);

        vm.prank(foundryDeployer);
        token.burnFrom(user, 15e18);
        assertEq(token.balanceOf(user), 5e18);
    }

    function test_RevertMintIf_NotCCTOperator() public {
        vm.expectPartialRevert(LibCCT.NotCCTOperator.selector);
        token.mint(foundryDeployer, 20e18);
    }

    function test_RevertBurnIf_NotCCTOperator() public {
        address notCCTOperator = makeAddr("notCCTOperator");
        vm.prank(notCCTOperator);
        vm.expectPartialRevert(LibCCT.NotCCTOperator.selector);
        token.burn(20e18);
    }

    function test_RevertBurnFromIf_NotCCTOperator() public {
        address user = makeAddr("user");
        vm.prank(foundryDeployer);
        token.mint(user, 20e18);
        assertEq(token.balanceOf(user), 20e18);

        address notCCTOperator = makeAddr("notCCTOperator");
        vm.prank(notCCTOperator);
        vm.expectPartialRevert(LibCCT.NotCCTOperator.selector);
        token.burnFrom(user, 1e18);
    }

    function test_TotalSupplyChanges() public {
        vm.startPrank(foundryDeployer);
        token.addCCTOperator(foundryDeployer);

        token.mint(foundryDeployer, 1000e18);
        assertEq(token.totalSupply(), 1000e18);

        token.burn(150e18);
        assertEq(token.totalSupply(), 850e18);

        vm.stopPrank();
    }

    function test_RevertIf_MaxSupplyExceeded() public {
        vm.startPrank(foundryDeployer);
        token.addCCTOperator(foundryDeployer);

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
        token.addCCTOperator(foundryDeployer);
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
        token.addCCTOperator(foundryDeployer);
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
        token.addCCTOperator(foundryDeployer);

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
        token.addCCTOperator(foundryDeployer);

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
        token.addCCTOperator(foundryDeployer);

        token.mint(user, 100e18);
        token.transferFrom(user, foundryDeployer, 30e18);

        assertEq(token.balanceOf(foundryDeployer), 30e18);
        assertEq(token.balanceOf(user), 70e18);
        assertEq(token.allowance(user, foundryDeployer), type(uint256).max);

        vm.stopPrank();
    }

    function test_DefaultBeforeUpdateValidationPass() public {
        address from = makeAddr("from");
        address to = makeAddr("to");
        tokenValidation.beforeUpdateValidation(from, to, 5);
    }

    function test_DefaultAfterUpdateValidation() public {
        address from = makeAddr("from");
        address to = makeAddr("to");
        tokenValidation.afterUpdateValidation(from, to, 5);
    }
}
