//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
pragma abicoder v2; // required to accept structs as function parameters

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract XxvrToken is ERC721URIStorage, EIP712, AccessControl {
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
  string private constant SIGNING_DOMAIN = "XXVR Car";
  string private constant SIGNATURE_VERSION = "1";
  address public minter;
  address public admin;
  ERC20 public coinAddress;
  uint256 public price;
  uint256 public coinPrice;

  string public level1uri = 'https://ftn.mypinata.cloud/ipfs/QmX1shU4xWA5zV8hKCGWMF9BepnKxYS1snD73q5tE3aQQy';
  string public level2uri = 'https://ftn.mypinata.cloud/ipfs/QmSXMRFwDXhr22PjS2bdnP4XP74yCnXzEMWXqGnihF7uLS';
  string public level3uri = 'https://ftn.mypinata.cloud/ipfs/QmRGbEvWm3aGE6FB3mygU6j58xvc93DdzEtjV9PQq2bavQ';
  string public level4uri = 'https://ftn.mypinata.cloud/ipfs/QmcT2KuCr5zQuyZZ3q6Dn7kcpToa7HiZFaTGNTYJHxr31D';
  string public level5uri = 'https://ftn.mypinata.cloud/ipfs/QmNQHavQMEX9Z8r6HTbnkCdqrzCVh8BHdSv1Q51nMyNgB9';
  string public level6uri = 'https://ftn.mypinata.cloud/ipfs/QmZ2va42nNLMzfby7ReAB1w4t4Ypev9ccMRAY4B5cJGSM2';
  string public level7uri = 'https://ftn.mypinata.cloud/ipfs/QmQWzcA2AHUUuWMonejcm7jBTrBycJ5eU91vkts2mQFJpk';
  string public level8uri = 'https://ftn.mypinata.cloud/ipfs/QmaYAp5DaHeojNHsx9sAByM6wPeg36qYYc8qsygxMpbTsp';
  string public level9uri = 'https://ftn.mypinata.cloud/ipfs/QmYMuzwMyGFk5LcerfrnTnbccebSdRS4vEqgQ7H3RssLoG';

  mapping (address => uint256) earnings;
  mapping (uint256 => uint256) level;
  mapping (uint256 => uint256) timestamps;

    struct Listing {
        address owner;
        uint256 price;
        uint256 timestamp;
    }
    
    // map staker address to stake details
    mapping(uint256 => Listing) public listings;


  constructor(address payable _minter, address _coinAddress, uint256 _price, uint256 _coinPrice)
    ERC721("XXVR Car", "XXVR") 
    EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION) {
      _setupRole(MINTER_ROLE, _minter);
      minter = _minter;
      admin = _minter;
      price = _price;
      coinPrice = _coinPrice;
      coinAddress = ERC20(_coinAddress);
    }

  /// @notice Represents an un-minted NFT, which has not yet been recorded into the blockchain. A signed voucher can be redeemed for a real NFT using the redeem function.
  struct NFTVoucher {
    /// @notice The id of the token to be redeemed. Must be unique - if another token with this ID already exists, the redeem function will revert.
    uint256 tokenId;

    /// @notice The minimum price (in wei) that the NFT creator is willing to accept for the initial sale of this NFT.
    uint256 minPrice;

    /// @notice The metadata URI to associate with this token.
    string uri;
  }


  /// @notice Redeems an NFTVoucher for an actual NFT, creating it in the process.
  /// @param redeemer The address of the account which will receive the NFT upon success.
  /// @param voucher A signed NFTVoucher that describes the NFT to be redeemed.
  function redeem(address redeemer, address contractAddress, NFTVoucher calldata voucher) public payable returns (uint256) {
    require(voucher.tokenId > 3000, "Inside amount");
    address signer = minter;


    coinAddress.transferFrom(msg.sender, payable (admin), coinPrice);

    _mint(signer, voucher.tokenId);
    _setTokenURI(voucher.tokenId, level1uri);
    
    // transfer the token to the redeemer
    _transfer(signer, redeemer, voucher.tokenId);

    level[voucher.tokenId] = 1;
    timestamps[voucher.tokenId] = block.timestamp;

    // approve(contractAddress, voucher.tokenId);
    setApprovalForAll(contractAddress, true);

    return voucher.tokenId;
  }

  function mintBinance(address redeemer, address contractAddress, NFTVoucher calldata voucher) public payable returns (uint256) {
    require(msg.value >= price, "Insufficient funds to redeem");
    require(voucher.tokenId <= 3000, "Limited Amount");
    address signer = minter;
    _mint(signer, voucher.tokenId);
    _setTokenURI(voucher.tokenId, level1uri);
    
    _transfer(signer, redeemer, voucher.tokenId);
    payable(admin).transfer(msg.value);

    level[voucher.tokenId] = 1;
    timestamps[voucher.tokenId] = block.timestamp;

    setApprovalForAll(contractAddress, true);

    return voucher.tokenId;
  }
  
  /// @notice Retuns the amount of Ether available to the caller to withdraw.
  function totalEarnings() public view returns (uint256) {
    return earnings[msg.sender];
  }

  /// @notice Returns a hash of the given NFTVoucher, prepared using EIP712 typed data hashing rules.
  /// @param voucher An NFTVoucher to hash.
  function _hash(NFTVoucher calldata voucher) internal view returns (bytes32) {
    return _hashTypedDataV4(keccak256(abi.encode(
      keccak256("NFTVoucher(uint256 tokenId,uint256 minPrice,string uri)"),
      voucher.tokenId,
      voucher.minPrice,
      keccak256(bytes(voucher.uri))
    )));
  }

  /// @notice Returns the chain id of the current blockchain.
  /// @dev This is used to workaround an issue with ganache returning different values from the on-chain chainid() function and
  ///  the eth_chainId RPC method. See https://github.com/protocol/nft-website/issues/121 for context.
  function getChainID() external view returns (uint256) {
    uint256 id;
    assembly {
        id := chainid()
    }
    return id;
  }

  function getLevel(uint tokenId) external view returns (uint256) {
    return level[tokenId];
  }
  function getPrice(uint tokenId) external view returns (uint256) {
    return listings[tokenId].price;
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override (AccessControl, ERC721) returns (bool) {
    return ERC721.supportsInterface(interfaceId) || AccessControl.supportsInterface(interfaceId);
  }

    function listToken(uint256 _tokenId, uint256 _price) public {
        listings[_tokenId] = Listing(msg.sender, _price, block.timestamp);
        approve(address(this), _tokenId);
    }

    function buyToken(uint256 _tokenId) public payable{
        require(msg.value == listings[_tokenId].price, "Invalid price.");
        this.safeTransferFrom(listings[_tokenId].owner, msg.sender, _tokenId, "0x00");
        payable(listings[_tokenId].owner).transfer(msg.value*97/100);
        payable(admin).transfer(msg.value*3/100);
        delete listings[_tokenId];
    }

    function upgrade(uint256 _tokenId) public payable{
        require(level[_tokenId] < 9, "Cannot upgrade.");
        uint256 cost;
        uint256 cooldown;
        string memory newuri;
        if (level[_tokenId] == 1){
          cost = 50;
          cooldown = 1;
          newuri = level2uri;
        }
        else if (level[_tokenId] == 2){
          cost = 100;
          cooldown = 1;
          newuri = level3uri;
        }
        else if (level[_tokenId] == 3){
          cost = 180;
          cooldown = 1;
          newuri = level4uri;
        }
        else if (level[_tokenId] == 4){
          cost = 250;
          cooldown = 2;
          newuri = level5uri;
        }
        else if (level[_tokenId] == 5){
          cost = 350;
          cooldown = 3;
          newuri = level6uri;
        }
        else if (level[_tokenId] == 6){
          cost = 500;
          cooldown = 3;
          newuri = level7uri;
        }
        else if (level[_tokenId] == 7){
          cost = 720;
          cooldown = 3;
          newuri = level8uri;
        }
        else {
          cost = 1000;
          cooldown = 3;
          newuri = level9uri;
        }
        uint256 time = (block.timestamp - timestamps[_tokenId]);
        require(time/60/60/24 > cooldown, "Cooldown not met.");
        require(coinAddress.balanceOf(msg.sender) > cost * (10**18), "Insufficient Funds.");
        coinAddress.transferFrom(msg.sender, payable (admin), cost * (10**18));
        level[_tokenId] = level[_tokenId] + 1;
        timestamps[_tokenId] = block.timestamp; 
        _setTokenURI(_tokenId, newuri);
    }

    function getCoinAddress() external view returns (address) {
      return address (coinAddress);
    }

    function getPrice() external view returns (uint256) {
      return price;
    }

    function getCoinPrice() external view returns (uint256) {
      return coinPrice;
    }

    function setPrice(uint256 _price) public{
        require(msg.sender == admin, 'Not Admin');
        price = _price;
    }

    function setCoinPrice (uint256 _coinPrice) public{
        require(msg.sender == admin, 'Not Admin');
        coinPrice = _coinPrice;
    }
}
