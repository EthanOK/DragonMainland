// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

// dragon metadata
contract DragonMetadata {
    // dragon job
    enum JobType {
        None,
        Water,
        Fire,
        Rock,
        Storm,
        Thunder
    }

    // dragon attributes
    enum AttrType {
        None,
        Health,
        Attack,
        Defense,
        Speed,
        LifeForce
    }

    // dragon skill
    enum SkillType {
        None,
        Horn,
        Ear,
        Wing,
        Tail,
        Talent
    }

    // dragon attribute 5
    struct Attribute {
        uint256 health;
        uint256 attack;
        uint256 defense;
        uint256 speed;
        uint256 lifeForce;
    }

    // dragon skill 5
    struct Skill {
        uint256 horn;
        uint256 ear;
        uint256 wing;
        uint256 tail;
        uint256 talent;
    }

    // dragon skills level 5
    struct Skills {
        uint256 horn;
        uint256 hornLevel;
        uint256 ear;
        uint256 earLevel;
        uint256 wing;
        uint256 wingLevel;
        uint256 tail;
        uint256 tailLevel;
        uint256 talent;
        uint256 talentLevel;
    }
}
