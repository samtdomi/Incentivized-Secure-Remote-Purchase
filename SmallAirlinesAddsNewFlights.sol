pragma solidity ^0.8.14;

import "./ownable.sol";

contract AirlineNewFlight is Ownable {
    
    /// @notice Flight Number will locate the details of that flight
    /// @dev Flight Number is a uint
    /// @return The details of the specific flight identified by its flight number
    mapping(uint => newFlight) public flightLocator;

    /// @dev Details of the flight are packaged in to the struct for mapping purpose and easy identification
    /// @dev Struct allows a mapping to hold several different flights and not just one per contract
    struct newFlight {
        uint flightNumber;
        string departureAirport;
        string departureCity;
        string arrivalAirport;
        string arrivalCity;
        uint departureTime;
        uint totalSeats;
        uint ticketPrice;
        uint premiumTwenty;
        uint premiumFive;
        uint remainingSeats;
        uint ticketId;
        PremiumState premiumState;
    }

    ///@return the owner address of the ticket number for a specific flight
    mapping(uint => mapping(uint => address)) public ticketOwner;
    enum PremiumState { Regular, Twenty , Five }
    
    mapping(address => bool ) hasInsurance;
    uint insurancePrice = .10 ether;
    

    /// @param _flightNumber is the fligt identification number 
    /// @param _totalSeats is the total amount of seats being sold for the flight 
    /// @param premiumTwenty is the surcharge added to the ticket price for the final twenty tickets OPTIONAL
    /// @param _premiumFive is the ADDITIONAL surcharge added to the ticket price for the final five tickets OPTIONAL
    /// @param _departureTime is the Unix Timestamp time of departure
    function createFlight(uint _flightNumber, string memory _departureAirport, string memory _departureCity, string memory _arrivalAirport, string memory _arrivalCity, 
    uint _departureTime, uint _totalSeats, uint _ticketPrice, uint _premiumTwenty, uint _premiumFive) public onlyOwner {

        flightLocator[_flightNumber] = newFlight(
            _flightNumber, _departureAirport, _departureCity, _arrivalAirport, _arrivalCity, 
            _departureTime, _totalSeats, _ticketPrice * (1 ether), _premiumTwenty * (1 ether), _premiumFive * (1 ether), _totalSeats, 0, PremiumState.Regular);
        

    }

    /// @notice Ensures that the customer can only purchase the ticket if they pay the full price of the ticket
    /// @dev _flightNumber is input by the customer to ensure they are paying the correct price for the flight they want
    modifier correctPrice(uint _flightNumber) {
        require(msg.value == flightLocator[_flightNumber].ticketPrice, "You must pay the exact amount of the ticket");
        _;
    }

    /// @notice Ensures that customer can only purchase a ticket if there are available seats 
    /// @dev Flight number is input by customer to ensure they are getting information from their desired flight
    modifier seatsAvailable(uint _flightNumber) {
        require(flightLocator[_flightNumber].remainingSeats != 0, "Flight is sold out");
        _;
    }

    /// @notice Customer purchases a ticket and can use their address to check their ticket Id
    /** 
        @dev First IF statement adds the premium twenty surcharge to the price of the 
        tickets between the final 19 - 6 tickets.
        Second IF statement adds an additional surcharge to the price of the final 5 tickets 
    */ 
    function purchaseTicket(uint _flightNumber) public seatsAvailable(_flightNumber) correctPrice(_flightNumber) {
        
        flighLocator[_flightNumber].ticketId ++;
        ticketOwner[_flightNumber][ticketId] = msg.sender;

        flightLocator[_flightNumber].remainingSeats --;

        if (flightLocator[_flightNumber].remainingSeats <= 20 && flightLocator[_flightNumber].remainingSeats > 5) {
            if (flightLocator[_flightNumber].premiumState == PremiumState.Regular) {
                flightLocator[_flightNumber].ticketPrice += flightLocator[_flightNumber].premiumTwenty;
                flightLocator[_flightNumber].premiumState = PremiumState.Twenty;
            }
        }

        if (flightLocator[_flightNumber].remainingSeats <= 5) {
            if (flightLocator[_flightNumber].premiumState == PremiumState.Twenty) {
                flightLocator[_flightNumber].ticketPrice += flightLocator[_flightNumber].premiumFive;
                flightLocator[_flightNumber].premiumState = PremiumState.Regular;
            }
        }
}


    /// @notice Allows a customer to purchase general flight insurance 
    /// @dev Flight insurance is not per flight but rather a general insurance coverage only needed to be purchased once
    /// @dev Customer address gets added to the mapping of those who have insurance as evidence of the coverage
    function purchaseInsurance() public {
        require(msg.value == insurancePrice);
        hasInsurance[msg.sender] = true;
    }

    /// @notice ONLY Airlines address that deployed this contract can withdraw total funds in the contract 
    /// @dev _owner comes from the owner generated by the inherited Ownable File and its Owner contract
    function airlinesWithdraw() external onlyOwner {
        _owner.transfer(address(this).balance);
    }


}
