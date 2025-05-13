// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

interface IVersioned {
    struct Version {
        uint256 major;
        uint256 minor;
        uint256 patch;
    }

    function getVersion() external view returns (Version memory);
    function isCompatible(Version memory otherVersion) external view returns (bool);
} 