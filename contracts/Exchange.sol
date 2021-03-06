pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

// ERC1155-ERC20 exchange based on https://github.com/HQ20/contracts/blob/master/contracts/classifieds/Classifieds.sol


/**
 * @title Exchange
 * @notice Implements the classifieds board market. The market will be governed
 * by an ERC20 token as currency, and an ERC721 token that represents the
 * ownership of the items being traded. Only ads for selling items are
 * implemented. The item tokenization is responsibility of the ERC721 contract
 * which should encode any item details.
 */
contract Exchange is ERC1155Holder{
    event TradeStatusChange(uint256 ad, bytes32 status);

    IERC20 currencyToken;
    IERC1155 itemToken;

    struct Trade {
        address poster;
        uint256 item;
        uint256 amount;
        uint256 price;
        bytes32 status; // Open, Executed, Cancelled
    }

    mapping(uint256 => Trade) public trades;

    uint256 tradeCounter;

    constructor (IERC20 _currencyToken, IERC1155 _itemToken){
        currencyToken = _currencyToken;
        itemToken = _itemToken;
        tradeCounter = 0;
    }

    /**
     * @dev Returns the details for a trade.
     * @param _trade The id for the trade.
     */
    function getTrade(uint256 _trade)
    public
    virtual
    view
    returns(address, uint256, uint256, bytes32)
    {
        Trade memory trade = trades[_trade];
        return (trade.poster, trade.item, trade.price, trade.status);
    }

    /**
     * @dev Opens a new trade. Puts _item in escrow.
     * @param _item The id for the item to trade.
     * @param _price The amount of currency for which to trade the item.
     */
    function openTrade(uint256 _item, uint256 _amount, uint256 _price)
    public
    virtual
    {
        itemToken.safeTransferFrom(msg.sender, address(this), _item, _amount, "");
        trades[tradeCounter] = Trade({
        poster: msg.sender,
        item: _item,
        amount: _amount,
        price: _price,
        status: "Open"
        });
        tradeCounter += 1;
        emit TradeStatusChange(tradeCounter - 1, "Open");
    }

    /**
     * @dev Executes a trade. Must have approved this contract to transfer the
     * amount of currency specified to the poster. Transfers ownership of the
     * item to the filler.
     * @param _trade The id of an existing trade
     */
    function executeTrade(uint256 _trade)
    public
    virtual
    {
        Trade memory trade = trades[_trade];
        require(trade.status == "Open", "Trade is not Open.");
        currencyToken.transferFrom(msg.sender, trade.poster, trade.price);
        itemToken.safeTransferFrom(address(this), msg.sender, trade.item, trade.amount, "");
        trades[_trade].status = "Executed";
        emit TradeStatusChange(_trade, "Executed");
    }

    /**
     * @dev Cancels a trade by the poster.
     * @param _trade The trade to be cancelled.
     */
    function cancelTrade(uint256 _trade)
    public
    virtual
    {
        Trade memory trade = trades[_trade];
        require(
            msg.sender == trade.poster,
            "Trade can be cancelled only by poster."
        );
        require(trade.status == "Open", "Trade is not Open.");
        itemToken.safeTransferFrom(address(this), trade.poster, trade.item, trade.amount, "");
        trades[_trade].status = "Cancelled";
        emit TradeStatusChange(_trade, "Cancelled");
    }
}