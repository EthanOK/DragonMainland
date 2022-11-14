// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

import "@openzeppelin/contracts/utils/Context.sol";

abstract contract Adminable is Context {
    address internal _admin;

    event AdminTransferred(
        address indexed previousAdmin,
        address indexed newAdmin
    );

    constructor() {
        _setAdmin(_msgSender());
    }

    function admin() public view virtual returns (address) {
        return _admin;
    }

    modifier onlyAdmin() {
        require(admin() == _msgSender(), "Adminable: caller is not the admin");
        _;
    }

    function renounceAdmin() external virtual onlyAdmin {
        _setAdmin(address(0));
    }

    function transferAdmin(address newAdmin) external virtual onlyAdmin {
        require(
            newAdmin != address(0),
            "Adminable: new admin is the zero address"
        );
        _setAdmin(newAdmin);
    }

    function _setAdmin(address newAdmin) private {
        address oldAdmin = _admin;
        _admin = newAdmin;
        emit AdminTransferred(oldAdmin, newAdmin);
    }
}
