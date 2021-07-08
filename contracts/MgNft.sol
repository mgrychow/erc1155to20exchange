pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract MgNft is ERC1155{
    constructor() ERC1155("/home/maciek/projects/nft/1155/{id}.json"){
    }

    function mint(address account, uint256 id, uint256 amount, bytes memory data) public
    {
         super._mint(account, id, amount, data);
    }
}
