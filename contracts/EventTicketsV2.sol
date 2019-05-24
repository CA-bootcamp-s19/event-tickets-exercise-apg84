pragma solidity ^0.5.0;

    /*
        The EventTicketsV2 contract keeps track of the details and ticket sales of multiple events.
     */
contract EventTicketsV2 {

    /*
        Define an public owner variable. Set it to the creator of the contract when it is initialized.
    */
    address payable public owner;
    uint   PRICE_TICKET = 100 wei;

    /*
        Create a variable to keep track of the event ID numbers.
    */
    uint public idGenerator;

    /*
        Define an Event struct, similar to the V1 of this contract.
        The struct has 6 fields: description, website (URL), totalTickets, sales, buyers, and isOpen.
        Choose the appropriate variable type for each field.
        The "buyers" field should keep track of addresses and how many tickets each buyer purchases.
    */

    struct Event {
        string description;
        string website;
        uint256 totalTickets;
        uint256 sales;
        mapping(address => uint256) buyers;
        bool isOpen;
    }

    /*
        Create a mapping to keep track of the events.
        The mapping key is an integer, the value is an Event struct.
        Call the mapping "events".
    */

    mapping(uint256 => Event) events;

    event LogEventAdded(string desc, string url, uint ticketsAvailable, uint eventId);
    event LogBuyTickets(address buyer, uint eventId, uint numTickets);
    event LogGetRefund(address accountRefunded, uint eventId, uint numTickets);
    event LogEndSale(address owner, uint balance);

    /*
        Create a modifier that throws an error if the msg.sender is not the owner.
    */

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier verifiedBuyer(address _buyer, uint256 _eventId) {
        require(events[_eventId].buyers[_buyer] > 0);
        _;
    }

    modifier paidEnough(uint256 _ticketCount) {
        require(msg.value >= _ticketCount*PRICE_TICKET);
        _;
    }

    modifier ticketsLeft(uint256 _ticketCount, uint256 _eventId) {
        require((events[_eventId].totalTickets - events[_eventId].sales) > _ticketCount);
        _;
    }

    modifier openEvent(uint256 _eventId) {
        require(events[_eventId].isOpen);
        _;
    }

    modifier returnExcessValue(uint _ticketCount) {
    //refund them after pay for item (why it is before, _ checks for logic before func)
    _;
    uint _price = PRICE_TICKET*_ticketCount;
    uint amountToRefund = msg.value - _price;
    msg.sender.transfer(amountToRefund);
  }

  constructor() public {
        owner = msg.sender;
    }


    /*
        Define a function called addEvent().
        This function takes 3 parameters, an event description, a URL, and a number of tickets.
        Only the contract owner should be able to call this function.
        In the function:
            - Set the description, URL and ticket number in a new event.
            - set the event to open
            - set an event ID
            - increment the ID
            - emit the appropriate event
            - return the event's ID
    */

    function addEvent(string memory _description, string memory _url, uint256 _totalTickets)
    public
    onlyOwner()
    {
        Event memory newEvent = Event({description: _description, website: _url, totalTickets: _totalTickets, sales: 0, isOpen: true});
        uint256 eventId = idGenerator;
        events[eventId] =  newEvent;
        idGenerator++;
        emit LogEventAdded(newEvent.description, newEvent.website, newEvent.totalTickets, eventId);

    }

    /*
        Define a function called readEvent().
        This function takes one parameter, the event ID.
        The function returns information about the event this order:
            1. description
            2. URL
            3. ticket available
            4. sales
            5. isOpen
    */     
    function readEvent(uint256 eventId) 
    view
    public
    returns(string memory description, string memory url, uint256 availableTickets, uint256 sales, bool isOpen)
    {
        Event memory currentEvent = events[eventId];
        return (currentEvent.description, currentEvent.website,
        currentEvent.totalTickets-currentEvent.sales, currentEvent.sales, currentEvent.isOpen);
    }


    /*
        Define a function called buyTickets().
        This function allows users to buy tickets for a specific event.
        This function takes 2 parameters, an event ID and a number of tickets.
        The function checks:
            - that the event sales are open
            - that the transaction value is sufficient to purchase the number of tickets
            - that there are enough tickets available to complete the purchase
        The function:
            - increments the purchasers ticket count
            - increments the ticket sale count
            - refunds any surplus value sent
            - emits the appropriate event
    */

    function buyTickets(uint256 eventId, uint256 numTickets) 
    payable 
    public 
    openEvent(eventId)
    paidEnough(numTickets)
    ticketsLeft(numTickets, eventId)
    returnExcessValue(numTickets)
    {
        events[eventId].buyers[msg.sender] += numTickets;
        events[eventId].sales += numTickets;
        emit LogBuyTickets(msg.sender, eventId, numTickets);
    }

    /*
        Define a function called getRefund().
        This function allows users to request a refund for a specific event.
        This function takes one parameter, the event ID.
        TODO:
            - check that a user has purchased tickets for the event
            - remove refunded tickets from the sold count
            - send appropriate value to the refund requester
            - emit the appropriate event
    */

    function getRefund(uint256 eventId) 
    public
    payable
    verifiedBuyer(msg.sender, eventId)
    openEvent(eventId)
    {
        uint256 numTickets = events[eventId].buyers[msg.sender];
        uint256 refundValue = numTickets*PRICE_TICKET;
        
        events[eventId].sales -= numTickets;
        
        msg.sender.transfer(refundValue);
        emit LogGetRefund(msg.sender, eventId, numTickets);
    }

    /*
        Define a function called getBuyerNumberTickets()
        This function takes one parameter, an event ID
        This function returns a uint, the number of tickets that the msg.sender has purchased.
    */

    function getBuyerNumberTickets(uint256 eventId)
    view
    public
    verifiedBuyer(msg.sender, eventId)
    returns(uint256 numTickets)
    {
        return events[eventId].buyers[msg.sender];
    }

    /*
        Define a function called endSale()
        This function takes one parameter, the event ID
        Only the contract owner can call this function
        TODO:
            - close event sales
            - transfer the balance from those event sales to the contract owner
            - emit the appropriate event
    */
    function endSale(uint256 eventId)
    public
    onlyOwner()
    {
        events[eventId].isOpen = false;
        uint256 valueToTransfer = events[eventId].sales*PRICE_TICKET;
        owner.transfer(valueToTransfer);
        emit LogEndSale(owner, valueToTransfer);
    }
}