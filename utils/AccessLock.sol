// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract AccessLock is Ownable, Pausable {
    // user => isAdmin ?
    mapping(address => bool) public isAdmin;
    mapping(address => bool) public isMinter;

    event AdminSet(address indexed admin, address indexed user, bool isEnabled);
    event MinterSet(address indexed admin, address indexed user, bool isEnabled);

    modifier onlyAdmin() {
        require(
            isAdmin[msg.sender] || msg.sender == owner(), 
            "Caller does not have Admin/Owner access"
            );
            _;
    }

    modifier onlyMinter() {
        require(
            isMinter[msg.sender],
            "Caller does not have Minter access"
        );
        _;
    }

    function setAdmin(address user, bool isEnabled) external onlyAdmin {
        require(user != address(0),"Invalid address");
        isAdmin[user] = isEnabled;
        emit AdminSet(msg.sender, user, isEnabled);
    }

    function setMinter(address user, bool isEnabled) external onlyAdmin returns (bool) {
        require(user != address(0),"Invalid address");
        isMinter[user] = isEnabled;
        emit MinterSet(msg.sender, user, isEnabled);
        return true;
    }

    function pause() external onlyAdmin {
        _pause();
    }

    function unpause() external onlyAdmin {
        _unpause();
    }
}
