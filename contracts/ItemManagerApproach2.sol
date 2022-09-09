// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.6;

contract Item {
    uint public priceInWei;
    uint public index;
    uint public pricePaid;

    ItemManager manager;

    constructor(ItemManager itemManager, uint itemPriceInWei, uint itemIndex) {
        priceInWei = itemPriceInWei;
        index = itemIndex;
        manager = itemManager;
    }

    receive() external payable {
        require(pricePaid == 0, "Item is already paid");
        require(msg.value >= priceInWei, "Item not fully paid");
        pricePaid += msg.value;
        // as we need to spend more than 2.3K of gas to perform more operations we use call instead of transfer to parent
       (bool success, ) =  address(manager).call{value: msg.value}(abi.encodeWithSignature("triggerPayment(uint256)", index));
       require(success, "The transaction was not successful");
    } 
}
contract ItemManager {

    // enums are numbers in reality, surprise!!! Not really
    enum SupplyChainState{Created, Paid, Delivered}

    struct ItemList {
        Item item;
        string id;
        uint price;
        SupplyChainState state;
    }

    mapping (uint => ItemList ) public items;
    uint private itemIndex;

    event SupplyChainStep(uint index, uint step, address itemAddress);
    event AmountPaid(uint index, uint price, uint amount);

    function createItem(string memory id, uint price) public {
        ItemList storage newItemElement = items[itemIndex];
        Item newItem = new Item(this, price, itemIndex);
        newItemElement.item = newItem;
        newItemElement.id = id;
        newItemElement.price = price;
        newItemElement.state = SupplyChainState.Created;
        emit SupplyChainStep(itemIndex, uint(newItemElement.state), address(newItem));
        itemIndex++;
    }

    function triggerPayment(uint index) public payable {                
        require(msg.value >= items[index].price, "You have to pay the price or more");
        require(items[index].state == SupplyChainState.Created, "Item is being already processed");
        items[index].state = SupplyChainState.Paid;
        emit AmountPaid(index, items[index].price, msg.value);
        emit SupplyChainStep(index, uint(items[index].state), address(items[index].item));
    }

    function triggerDelivery(uint index) public {
        require(items[index].state == SupplyChainState.Paid, "Item is being already processed");
        items[index].state = SupplyChainState.Delivered;
        emit SupplyChainStep(index, uint(items[index].state), address(items[index].item));
    }
}