// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.6;

contract ItemManager {

    // enums are numbers in reality, surprise!!! Not really
    enum SupplyChainState{Created, Paid, Delivered}

    struct Item {
        string id;
        uint price;
        SupplyChainState state;
    }

    mapping (uint => Item ) public items;
    uint private itemIndex;

    event SupplyChainStep(uint index, uint step);
    event AmountPaid(uint index, uint price, uint amount);

    function createItem(string memory id, uint price) public {
        Item storage newItem = items[itemIndex];
        newItem.id = id;
        newItem.price = price;
        newItem.state = SupplyChainState.Created;
        emit SupplyChainStep(itemIndex, uint(newItem.state));
        itemIndex++;
    }

    function triggerPayment(uint index) public payable {                
        require(msg.value >= items[index].price, "You have to pay the price or more");
        require(items[index].state == SupplyChainState.Created, "Item is being already processed");
        items[index].state = SupplyChainState.Paid;
        emit AmountPaid(index, items[index].price, msg.value);
        emit SupplyChainStep(index, uint(items[index].state));
    }

    function triggerDelivery(uint index) public {
        require(items[index].state == SupplyChainState.Paid, "Item is being already processed");
        items[index].state = SupplyChainState.Delivered;
        emit SupplyChainStep(index, uint(items[index].state));
    }
}