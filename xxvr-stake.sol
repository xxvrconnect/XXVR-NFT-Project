// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./xxvr-token.sol";

contract XxvrStake is ERC721Holder {
    address public parentNFT;
    address tracker_0x_address;
    address admin;

    struct Stake {
        address owner;
        uint256 amount;
        uint256 timestamp;
    }

    // map staker address to stake details
    mapping(uint256 => Stake) public stakes;

    // map staker to total staking time 
    mapping(address => uint256) public stakingTime;    

    constructor(address parent, address coinAddress) {
        parentNFT = parent; // Change it to your NFT contract addr
        tracker_0x_address = coinAddress;
        admin = msg.sender;
    }

    function stake(uint256 _tokenId, uint256 _amount) public {
        require (IERC20(tracker_0x_address).balanceOf(address(msg.sender)) > 2*(10**18), "User must have COIN to start staking.");
        stakes[_tokenId] = Stake(msg.sender, _amount, block.timestamp); 
        IERC721(parentNFT).safeTransferFrom(msg.sender, address(this), _tokenId, "0x00");
    } 

    function getTimeStaked(uint256 _tokenId) external view returns (uint256) {
        uint256 time = (block.timestamp - stakes[_tokenId].timestamp)/60/60/24;
        return time;
    }

    function unstake(uint256 _tokenId) public {
        require(msg.sender == stakes[_tokenId].owner, "Invalid user.");
        IERC721(parentNFT).safeTransferFrom(address(this), msg.sender, _tokenId, "0x00");
        uint256 time = (block.timestamp - stakes[_tokenId].timestamp)/60/60/24;
        uint256 level = XxvrToken (parentNFT).getLevel(_tokenId);
        uint256 rate = 0;
        if (level == 1){
            rate = 160;
        }
        else if(level == 2){
            rate = 200;
        }
        else if(level == 3){
            rate = 270;
        }
        else if(level == 4){
            rate = 360;
        }
        else if(level == 5){
            rate = 520;
        }
        else if(level == 6){
            rate = 800;
        }
        else if(level == 7){
            rate = 1279;
        }
        else if(level == 8){
            rate = 2107;
        }
        else if(level == 9){
            rate = 3620;
        }
        else{
            rate = 0;
        }
        ERC20(tracker_0x_address).transfer(msg.sender, time * rate * (10 ** 17));
        delete stakes[_tokenId];
    }

    function getBalance() external view returns (uint256) {
      return IERC20(tracker_0x_address).balanceOf(address(this));
    }

    function withdraw (uint256 amount) public {
        require(msg.sender == admin, 'Not Admin');
        ERC20(tracker_0x_address).transfer(msg.sender, amount);
    }

     function onERC721Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4) {
        return bytes4(keccak256("onERC721Received(address,address,uint256,uint256,bytes)"));
    }

}