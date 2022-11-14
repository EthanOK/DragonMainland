// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IDragonMainToken is IERC721 {
    function getDragonAttribute(uint256 _tokenId, uint256 _attrId)
        external
        view
        returns (uint256 attr);

    function dragonSkills(uint256 _tokenId)
        external
        view
        returns (
            uint256 horn,
            uint256 ear,
            uint256 wing,
            uint256 tail,
            uint256 talent
        );

    function getDragonSkill(uint256 _tokenId, uint256 _skillId)
        external
        view
        returns (uint256 skill);

    function burn(uint256 tokenId) external;

    function setDragonSkill(
        uint256 _tokenId,
        uint256 _skillId,
        uint256 _value,
        uint256 _timestamp,
        bytes memory _sign
    ) external returns (bool);

    function setDragonAttribute(
        uint256 _tokenId,
        uint256 _attrId,
        uint256 _value,
        uint256 _timestamp,
        bytes memory _sign
    ) external returns (bool);

    function getDragonJob(uint256 _tokenId) external view returns (uint8 job);
}
