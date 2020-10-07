pragma solidity >=0.5.8 <0.8.0;

import "../../interfaces/IERC20.sol";
import "../../interfaces/ERC20.sol";
import "../../interfaces/WETH.sol";

import "../../libraries/SafeMath.sol";
import "../../libraries/Address.sol";
import "../../libraries/SafeERC20.sol";

import "./ElfStrategy.sol";

contract Elf is ERC20 {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    IERC20 public weth;

    address public governance;
    address payable public strategy;

    constructor() public ERC20("Element Liquidity Fund", "ELF") {
        governance = msg.sender;
    }

    function balance() public view returns (uint256) {
        return address(this).balance.add(ElfStrategy(strategy).balanceOf());
    }

    function setGovernance(address _governance) public {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }

    function setStrategy(address payable _strategy) public {
        require(msg.sender == governance, "!governance");
        strategy = _strategy;
    }

    function available() public view returns (uint256) {
        // TODO: implement min/max logic
        return 0;
    }

    function invest() public {
        // todo: should we restrict who can call this?
        // WB: if ppl want to pay the gas fees, then by all meeeeans
        strategy.transfer(address(this).balance);
        ElfStrategy(strategy).allocate(address(this).balance);
    }

    // for depositing WETH, remove payable later
    function deposit() public payable {
        uint256 _amount = msg.value;
        uint256 _pool = balance();
        uint256 _shares = 0;
        //weth.safeTransferFrom(msg.sender, address(this), _amount);
        if (totalSupply() == 0) {
            _shares = _amount;
        } else {
            _shares = (_amount.mul(totalSupply())).div(_pool);
        }
        _mint(msg.sender, _shares);
        invest();
    }

    // for depositing ETH (subsequently wrapped and deposited)
    function depositETH() public payable {
        // call WETH.deposit()
    }

    function withdraw(uint256 _shares) public {
        uint256 r = (balance().mul(_shares)).div(totalSupply());
        _burn(msg.sender, _shares);

        // Check balance
        uint256 b = address(this).balance;
        if (b < r) {
            uint256 _withdraw = r.sub(b);
            ElfStrategy(strategy).deallocate(_withdraw);
            ElfStrategy(strategy).withdraw();
            uint256 _after = address(this).balance;
            uint256 _diff = _after.sub(b);
            // todo: ??
            if (_diff < _withdraw) {
                r = b.add(_diff);
            }
        }
        msg.sender.transfer(r);
    }

    receive() external payable {}
}