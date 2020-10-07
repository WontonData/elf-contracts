pragma solidity >=0.5.8 <0.8.0;

import "../../interfaces/IERC20.sol";

import "../../libraries/SafeMath.sol";
import "../../libraries/Address.sol";
import "../../libraries/SafeERC20.sol";

import "./assets/YearnDaiVault.sol";
import "./assets/YearnUsdcVault.sol";
import "./assets/YearnTusdVault.sol";

import "../../converter/interface/ElementConverter.sol";

contract ElfStrategy {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    struct Allocation {
        address asset;
        uint256 percent;
    }

    Allocation[] public allocations;
    uint256 public numAllocations;

    address public governance;
    address public fund;
    address public converter;

    address public constant ETH = address(
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE
    );

    constructor(address _fund) public {
        governance = msg.sender;
        fund = _fund;
    }

    function setGovernance(address _governance) public {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }

    function setConverter(address _converter) public {
        require(msg.sender == governance, "!governance");
        converter = _converter;
    }

    function setAllocations(
        address[] memory _assets,
        uint256[] memory _percents,
        uint256 _numAllocations
    ) public {
        require(msg.sender == governance, "!governance");
        // todo: validate that allocations add to 100
        delete allocations;
        for (uint256 i = 0; i < _numAllocations; i++) {
            allocations.push(Allocation(_assets[i], _percents[i]));
        }
        numAllocations = _numAllocations;
    }

    function allocate(uint256 _amount) public {
        require(msg.sender == fund, "!fund");
        for (uint256 i = 0; i < numAllocations; i++) {
            // convert weth to asset base type (e.g. dai)
            uint256 _assetAmount = _amount.mul(allocations[i].percent).div(100);
            // 0 = loan, 1 = swap
            ElementConverter(converter).convert(
                ETH,
                allocations[i].asset,
                _assetAmount,
                0
            );
            // TODO: deposit into asset vault
        }
    }

    function deallocate(uint256 _amount) public {
        require(msg.sender == fund, "!fund");

        for (uint256 i = 0; i < numAllocations; i++) {
            // TODO: withdraw from  vault
            // TODO: convert to weth
        }
    }

    function withdraw() public {
        require(msg.sender == fund, "!fund");
        msg.sender.transfer(address(this).balance);
    }

    function balanceOf() public view returns (uint256) {
        // TODO: add balances of assets
        return address(this).balance;
    }

    receive() external payable {}
}