// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {IVersioned} from "../interfaces/IVersioned.sol";

library LibVersion {
    bytes32 constant VERSION_STORAGE_POSITION = keccak256("stobox.version.storage");

    struct VersionStorage {
        IVersioned.Version version;
        mapping(address => IVersioned.Version) facetVersions;
    }

    function versionStorage() internal pure returns (VersionStorage storage vs) {
        bytes32 position = VERSION_STORAGE_POSITION;
        assembly {
            vs.slot := position
        }
    }

    function setVersion(uint256 major, uint256 minor, uint256 patch) internal {
        VersionStorage storage vs = versionStorage();
        vs.version = IVersioned.Version(major, minor, patch);
    }

    function setFacetVersion(address facet, uint256 major, uint256 minor, uint256 patch) internal {
        VersionStorage storage vs = versionStorage();
        vs.facetVersions[facet] = IVersioned.Version(major, minor, patch);
    }

    function getVersion() internal view returns (IVersioned.Version memory) {
        return versionStorage().version;
    }

    function getFacetVersion(address facet) internal view returns (IVersioned.Version memory) {
        return versionStorage().facetVersions[facet];
    }

    function isCompatible(IVersioned.Version memory v1, IVersioned.Version memory v2) internal pure returns (bool) {
        // Major version must match exactly
        if (v1.major != v2.major) return false;
        
        // Minor version can be higher in v2
        if (v1.minor > v2.minor) return false;
        
        // Patch version can be higher in v2 if minor versions match
        if (v1.minor == v2.minor && v1.patch > v2.patch) return false;
        
        return true;
    }
} 