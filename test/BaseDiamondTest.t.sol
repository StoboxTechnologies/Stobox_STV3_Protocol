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
import {IDiamondLoupe} from "src/interfaces/IDiamondLoupe.sol";
import {IBaseERC20} from "src/interfaces/IBaseERC20.sol";

import {LibCCT} from "src/libraries/LibCCT.sol";
import {DeployDiamondLibrary} from "script/Deploy.s.sol";

contract BaseDiamondTest is Test {
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
    IDiamondLoupe diamondLoupe;

    function cutFacetsPush(address facetAddress) internal {
        facetCuts.push(
            IDiamond.FacetCut({facetAddress: facetAddress, action: IDiamond.FacetCutAction.Add, functionSelectors: sig})
        );
    }

    function setUp() public {
        (baseERC20, diamondCutFacet, diamondLoupeFacet, cctFacet, defaultValidationFacet) = DeployDiamondLibrary
            .deployDiamond(
            foundryDeployer, foundryDeployer, name, symbol, decimals, maxSupply, sig, facetCuts, sigIm, facetCutsIm
        );

        token = IBaseERC20(address(baseERC20));
        diamondLoupe = IDiamondLoupe(address(baseERC20));
        console.log("New ERC20 Token deployed to", address(baseERC20));
    }

    function test_AllFiveFacetsAdded() public view {
        uint256 len = diamondLoupe.facetAddresses().length;
        assertEq(len, 5);
    }

    function test_FunctionSelectorsAssociatedToCorrectFacets() public view {
        address cut = diamondLoupe.facetAddress(diamondCutFacet.diamondCut.selector);
        assertEq(address(diamondCutFacet), cut);

        address loupe = diamondLoupe.facetAddress(diamondLoupe.facets.selector);
        assertEq(address(diamondLoupeFacet), loupe);

        address cct = diamondLoupe.facetAddress(cctFacet.burn.selector);
        assertEq(address(cctFacet), cct);

        address validator = diamondLoupe.facetAddress(defaultValidationFacet.beforeUpdateValidation.selector);
        assertEq(address(defaultValidationFacet), validator);
    }
}
