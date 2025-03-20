// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IERC20Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import {ITransferValidation} from "../interfaces/ITransferValidation.sol";

library LibERC20 {
    struct ERC20Storage {
        mapping(address account => uint256) _balances;
        mapping(address account => mapping(address spender => uint256)) _allowances;
        uint256 _totalSupply;
        string _name;
        string _symbol;
        uint8 _decimals;
        uint256 _maxSupply;
    }

    bytes32 constant ERC20_POSITION = keccak256("erc20.storage");

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function erc20Storage() internal pure returns (ERC20Storage storage storageStruct) {
        bytes32 position = ERC20_POSITION;
        assembly {
            storageStruct.slot := position
        }
    }

    // @dev Returns the name of the token.
    function name() internal view returns (string memory) {
        return erc20Storage()._name;
    }

    // @dev Returns the symbol of the token, usually a shorter version of the
    function symbol() internal view returns (string memory) {
        return erc20Storage()._symbol;
    }

    // @dev Returns the number of decimals used to get its user representation.
    function decimals() internal view returns (uint8) {
        return erc20Storage()._decimals;
    }

    // @dev See {IERC20-totalSupply}.
    function totalSupply() internal view returns (uint256) {
        return erc20Storage()._totalSupply;
    }

    // @dev See {IERC20-balanceOf}.
    function balanceOf(address account) internal view returns (uint256) {
        return erc20Storage()._balances[account];
    }

    // @dev Returns the max supply of the token, 0 if unlimited.
    function maxSupply() internal view returns (uint256) {
        return erc20Storage()._maxSupply;
    }

    // Requirements:
    // - `to` cannot be the zero address.
    // - the caller must have a balance of at least `value`.
    function transfer(address to, uint256 value) internal returns (bool) {
        address owner_ = _msgSender();
        _transfer(owner_, to, value);
        return true;
    }

    function allowance(address owner_, address spender) internal view returns (uint256) {
        return erc20Storage()._allowances[owner_][spender];
    }

    // NOTE: If `value` is the maximum `uint256`, the allowance is not updated on
    // `transferFrom`. This is semantically equivalent to an infinite approval.
    // Requirements:
    // - `spender` cannot be the zero address.
    function approve(address spender, uint256 value) internal returns (bool) {
        address owner_ = _msgSender();
        _approve(owner_, spender, value);
        return true;
    }

    // Skips emitting an {Approval} event indicating an allowance update. This is not required by the ERC.
    // NOTE: Does not update the allowance if the current allowance
    // is the maximum `uint256`.
    // Requirements:
    // - `from` and `to` cannot be the zero address.
    // - `from` must have a balance of at least `value`.
    // - the caller must have allowance for ``from``'s tokens of at least `value`
    function transferFrom(address from, address to, uint256 value) internal returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, value);
        _transfer(from, to, value);
        return true;
    }

    // @dev Moves a `value` amount of tokens from `from` to `to`.
    // Emits a {Transfer} event.
    function _transfer(address from, address to, uint256 value) internal {
        if (from == address(0)) {
            revert IERC20Errors.ERC20InvalidSender(address(0));
        }
        if (to == address(0)) {
            revert IERC20Errors.ERC20InvalidReceiver(address(0));
        }
        _update(from, to, value);
    }

    // @dev Emits a {Transfer} event.
    function _update(address from, address to, uint256 value) internal {
        ITransferValidation(address(this)).beforeUpdateValidation(from, to, value);

        ERC20Storage storage erc20s = erc20Storage();

        if (from == address(0)) {
            // Overflow check required: The rest of the code assumes that totalSupply never overflows
            erc20s._totalSupply += value;
        } else {
            uint256 fromBalance = erc20s._balances[from];
            if (fromBalance < value) {
                revert IERC20Errors.ERC20InsufficientBalance(from, fromBalance, value);
            }
            unchecked {
                // Overflow not possible: value <= fromBalance <= totalSupply.
                erc20s._balances[from] = fromBalance - value;
            }
        }

        if (to == address(0)) {
            unchecked {
                // Overflow not possible: value <= totalSupply or value <= fromBalance <= totalSupply.
                erc20s._totalSupply -= value;
            }
        } else {
            unchecked {
                // Overflow not possible: balance + value is at most totalSupply, which we know fits into a uint256.
                erc20s._balances[to] += value;
            }
        }

        emit Transfer(from, to, value);

        ITransferValidation(address(this)).afterUpdateValidation(from, to, value);
    }

    // @dev Creates a `value` amount of tokens and assigns them to `account`, by transferring it from address(0).
    // Relies on the `_update` mechanism
    // Emits a {Transfer} event with `from` set to the zero address.
    function _mint(address account, uint256 value) internal {
        if (account == address(0)) {
            revert IERC20Errors.ERC20InvalidReceiver(address(0));
        }
        _update(address(0), account, value);
    }

    // @dev Destroys a `value` amount of tokens from `account`, lowering the total supply.
    // Relies on the `_update` mechanism.
    // Emits a {Transfer} event with `to` set to the zero address.
    function _burn(address account, uint256 value) internal {
        if (account == address(0)) {
            revert IERC20Errors.ERC20InvalidSender(address(0));
        }
        _update(account, address(0), value);
    }

    // @dev Sets `value` as the allowance of `spender` over the `owner` s tokens.
    // Emits an {Approval} event.
    // - `owner` cannot be the zero address.
    // - `spender` cannot be the zero address.
    function _approve(address owner_, address spender, uint256 value) internal {
        _approve(owner_, spender, value, true);
    }

    // @dev Variant of {_approve} with an optional flag to enable or disable the {Approval} event.
    function _approve(address owner_, address spender, uint256 value, bool emitEvent) internal {
        ERC20Storage storage erc20s = erc20Storage();

        if (owner_ == address(0)) {
            revert IERC20Errors.ERC20InvalidApprover(address(0));
        }
        if (spender == address(0)) {
            revert IERC20Errors.ERC20InvalidSpender(address(0));
        }
        erc20s._allowances[owner_][spender] = value;
        if (emitEvent) {
            emit Approval(owner_, spender, value);
        }
    }

    // @dev Updates `owner_` s allowance for `spender` based on spent `value`.
    // Does not update the allowance value in case of infinite allowance.
    // Revert if not enough allowance is available.
    // Does not emit an {Approval} event.
    function _spendAllowance(address owner_, address spender, uint256 value) internal {
        uint256 currentAllowance = allowance(owner_, spender);
        if (currentAllowance != type(uint256).max) {
            if (currentAllowance < value) {
                revert IERC20Errors.ERC20InsufficientAllowance(spender, currentAllowance, value);
            }
            unchecked {
                _approve(owner_, spender, currentAllowance - value, false);
            }
        }
    }

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }
}
