// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {Script} from "forge-std/Script.sol";
import {DiamondInit} from "src/upgradeInitializers/DiamondInit.sol";
import {DiamondLoupeFacet} from "src/facets/DiamondLoupeFacet.sol";
import {DiamondCutFacet} from "src/facets/DiamondCutFacet.sol";
import {CCTFacet} from "src/facets/CCTFacet.sol";
import {StoboxProtocolSTV3} from "src/StoboxProtocolSTV3.sol";
import {DefaultValidationFacet} from "src/facets/DefaultValidationFacet.sol";

import {IDiamond} from "src/interfaces/IDiamond.sol";
import {IDiamondCut} from "src/interfaces/IDiamondCut.sol";

library DeployDiamondLibrary {
    function cutFacetsPush(address facetAddress, bytes4[] storage sig, IDiamond.FacetCut[] storage facetCuts)
        internal
    {
        facetCuts.push(
            IDiamond.FacetCut({facetAddress: facetAddress, action: IDiamond.FacetCutAction.Add, functionSelectors: sig})
        );
    }

    function deployDiamond(
        address deployer,
        address owner,
        string memory name,
        string memory symbol,
        uint8 decimals,
        uint256 maxSupply,
        bytes4[] storage sig,
        IDiamond.FacetCut[] storage facetCuts,
        bytes4[] storage sigIm,
        IDiamond.FacetCut[] storage facetCutsIm
    ) internal returns (StoboxProtocolSTV3, DiamondCutFacet, DiamondLoupeFacet, CCTFacet, DefaultValidationFacet) {
        // Deploy DiamondInit
        // DiamondInit provides a function that is called when the diamond is upgraded or deployed to initialize state variables
        // Read about how the diamondCut function works in the EIP2535 Diamonds standard
        DiamondInit diamondInit = new DiamondInit();

        // Deploy facets and set the `facetCuts` variable

        // DiamondCutFacet
        DiamondCutFacet diamondCutFacet = new DiamondCutFacet();
        sig.push(diamondCutFacet.diamondCut.selector);

        cutFacetsPush(address(diamondCutFacet), sig, facetCuts);

        sig.pop();

        // DiamondLoupeFacet
        DiamondLoupeFacet diamondLoupeFacet = new DiamondLoupeFacet();
        sig.push(diamondLoupeFacet.facets.selector);
        sig.push(diamondLoupeFacet.facetFunctionSelectors.selector);
        sig.push(diamondLoupeFacet.facetAddresses.selector);
        sig.push(diamondLoupeFacet.facetAddress.selector);
        sig.push(diamondLoupeFacet.supportsInterface.selector);

        cutFacetsPush(address(diamondLoupeFacet), sig, facetCuts);

        uint256 len = sig.length;
        for (uint256 i = 0; i < len; i++) {
            sig.pop();
        }

        //CCTFacet
        CCTFacet cCTFacet = new CCTFacet();
        sig.push(cCTFacet.burn.selector);
        sig.push(cCTFacet.burnFrom.selector);
        sig.push(cCTFacet.mint.selector);
        sig.push(cCTFacet.transferAndCall.selector);
        sig.push(cCTFacet.addCCTOperator.selector);
        sig.push(cCTFacet.removeCCTOperator.selector);
        sig.push(cCTFacet.getCCTOperators.selector);
        sig.push(cCTFacet.isCCTOperator.selector);

        cutFacetsPush(address(cCTFacet), sig, facetCuts);

        uint256 len1 = sig.length;
        for (uint256 i = 0; i < len1; i++) {
            sig.pop();
        }

        // DefaultValidationFacet
        DefaultValidationFacet defaultValidationFacet = new DefaultValidationFacet();
        sig.push(defaultValidationFacet.beforeUpdateValidation.selector);
        sig.push(defaultValidationFacet.afterUpdateValidation.selector);

        cutFacetsPush(address(defaultValidationFacet), sig, facetCuts);

        uint256 len2 = sig.length;
        for (uint256 i = 0; i < len2; i++) {
            sig.pop();
        }

        // Initialization of function
        bytes memory functionCall =
            abi.encodeWithSignature("init(string,string,uint8,uint256)", name, symbol, decimals, maxSupply);

        StoboxProtocolSTV3.DiamondArgs memory diamondArgs = StoboxProtocolSTV3.DiamondArgs({
            deployer: deployer,
            owner: owner,
            init: address(diamondInit),
            initCalldata: functionCall
        });

        // deploy Diamond
        StoboxProtocolSTV3 diamondFacet = new StoboxProtocolSTV3(facetCuts, diamondArgs);

        // Diamond itself!!!
        sigIm.push(diamondFacet.transfer.selector);
        sigIm.push(diamondFacet.approve.selector);
        sigIm.push(diamondFacet.transferFrom.selector);
        sigIm.push(diamondFacet.setDeployer.selector);
        sigIm.push(diamondFacet.transferOwnership.selector);
        sigIm.push(diamondFacet.name.selector);
        sigIm.push(diamondFacet.symbol.selector);
        sigIm.push(diamondFacet.decimals.selector);
        sigIm.push(diamondFacet.totalSupply.selector);
        sigIm.push(diamondFacet.balanceOf.selector);
        sigIm.push(diamondFacet.maxSupply.selector);
        sigIm.push(diamondFacet.allowance.selector);
        sigIm.push(diamondFacet.deployer.selector);
        sigIm.push(diamondFacet.owner.selector);

        facetCutsIm.push(
            IDiamond.FacetCut({
                facetAddress: address(diamondFacet),
                action: IDiamond.FacetCutAction.Add,
                functionSelectors: sigIm
            })
        );

        IDiamondCut(address(diamondFacet)).diamondCut(facetCutsIm, address(0), "0x");

        return (diamondFacet, diamondCutFacet, diamondLoupeFacet, cCTFacet, defaultValidationFacet);
    }
}

contract DeployDiamondScript is Script {
    bytes4[] sig;
    IDiamond.FacetCut[] facetCuts;

    bytes4[] sigIm;
    IDiamond.FacetCut[] facetCutsIm;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.envAddress("DEPLOYER");
        address owner = vm.envAddress("OWNER");

        string memory name = "DEMO Stobox Token v.3";
        string memory symbol = "DEMOSTBU";
        uint8 decimals = 18;
        uint256 maxSupply = 250_000_000e18;

        vm.startBroadcast(deployerPrivateKey);

        DeployDiamondLibrary.deployDiamond(
            deployer, owner, name, symbol, decimals, maxSupply, sig, facetCuts, sigIm, facetCutsIm
        );

        vm.stopBroadcast();
    }
}
