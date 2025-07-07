// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.9.0/contracts/token/ERC20/ERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.9.0/contracts/access/Ownable.sol";

contract SimpleDEX is Ownable {
    IERC20 public tokenA;
    IERC20 public tokenB;

    uint256 public reserveA;
    uint256 public reserveB;

    event LiquidityAdded(uint256 amountA, uint256 amountB);
    event LiquidityRemoved(uint256 amountA, uint256 amountB);
    event Swap(address indexed user, address fromToken, address toToken, uint256 amountIn, uint256 amountOut);

    constructor(address _tokenA, address _tokenB) {
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
        _transferOwnership(msg.sender);
    }

    function addLiquidity(uint256 amountA, uint256 amountB) external onlyOwner {
        require(amountA > 0 && amountB > 0, "Amounts must be greater than 0");

        tokenA.transferFrom(msg.sender, address(this), amountA);
        tokenB.transferFrom(msg.sender, address(this), amountB);

        reserveA += amountA;
        reserveB += amountB;

        emit LiquidityAdded(amountA, amountB);
    }

    function removeLiquidity(uint256 amountA, uint256 amountB) external onlyOwner {
        require(amountA <= reserveA && amountB <= reserveB, "Not enough liquidity");

        tokenA.transfer(msg.sender, amountA);
        tokenB.transfer(msg.sender, amountB);

        reserveA -= amountA;
        reserveB -= amountB;

        emit LiquidityRemoved(amountA, amountB);
    }

    function swapAforB(uint256 amountAIn) external {
        require(amountAIn > 0, "Amount must be greater than 0");

        tokenA.transferFrom(msg.sender, address(this), amountAIn);

        uint256 amountBOut = getSwapAmount(amountAIn, reserveA, reserveB);

        require(amountBOut <= reserveB, "Not enough TokenB liquidity");

        tokenB.transfer(msg.sender, amountBOut);

        reserveA += amountAIn;
        reserveB -= amountBOut;

        emit Swap(msg.sender, address(tokenA), address(tokenB), amountAIn, amountBOut);
    }

    function swapBforA(uint256 amountBIn) external {
        require(amountBIn > 0, "Amount must be greater than 0");

        tokenB.transferFrom(msg.sender, address(this), amountBIn);

        uint256 amountAOut = getSwapAmount(amountBIn, reserveB, reserveA);

        require(amountAOut <= reserveA, "Not enough TokenA liquidity");

        tokenA.transfer(msg.sender, amountAOut);

        reserveB += amountBIn;
        reserveA -= amountAOut;

        emit Swap(msg.sender, address(tokenB), address(tokenA), amountBIn, amountAOut);
    }

    function getSwapAmount(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) internal pure returns (uint256) {
        return (amountIn * reserveOut) / (reserveIn + amountIn);
    }

    function getPrice(address _token) external view returns (uint256 price) {
        if (_token == address(tokenA)) {
            require(reserveA > 0, "No liquidity");
            price = (reserveB * 1e18) / reserveA; 
        } else if (_token == address(tokenB)) {
            require(reserveB > 0, "No liquidity");
            price = (reserveA * 1e18) / reserveB;
        } else {
            revert("Invalid token");
        }
    }
}
