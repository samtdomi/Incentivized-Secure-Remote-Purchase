pragma solidity ^0.8.14;

import "./Ownable.sol";

contract VehicleRentals is Ownable {

    /// @notice Creates the specifications for a vehicle 
    /// @dev String is the name of the Vehicle 
    /// @dev vehicleYear and duration are stacked together with uint32 to optimize gas 
    mapping(string => VehicleInfo) public vehicles;
    struct VehicleInfo {
        string vehicleName;
        string vehicleModel;
        uint32 vehicleYear;
        uint32 duration;
        uint dailyPrice;
        uint startDate;
        uint endDate;
        bool isRented;
        uint finalPrice;
        bool checkedPrice;
    }

    ///@notice Matches the vehicle to the address of its renter while it is rented, if not rented, no address
    /// @dev String is the name of the vehicle 
    mapping(string => address) public vehicleAndRenter; 
    
    /// @return the amount required as a deposit to rent a vehicle
    uint public deposit = .20 ether;
    /// @return the price of the late fee for each day that the vehicle is late 
    uint public lateFeePerDay = .03 ether;


    ///@return The Daily price of the specified vehicle 
    function vehicleDailyPrice(string memory _vehicleName) external view returns(uint) {
        return vehicles[_vehicleName].dailyPrice;
    }

    /// @notice The owner gets to add a new vehicle and its information to the inventory of available vehicles
    /// @param _dailyPrice is the price that it costs to rent the vehicle per day 
    function createVehicle(string memory _vehicleName, string memory _vehicleModel, uint32 _vehicleYear, uint _dailyPrice) public onlyOwner {
        vehicles[_vehicleName] = VehicleInfo(
            _vehicleName, _vehicleModel, _vehicleYear, 0, _dailyPrice * (1 ether), 0, 0, false, 0, false);
        
    }

    /// @notice Ensures that a renter can only rent a vehicle if it is available and not in use
    modifier isAvailable(string memory _vehicleName) {
        require(vehicles[_vehicleName].isRented == false, "The vehicle is currently unavailable");
        _; 
    }

    /// @notice Renter gets his address assigned to the vehicle indicating that he/she is the renter of that vehicle
    /// @notice Renter sets the start and end date that they wish to have the vehicle 
    /// @dev The vehicle becomes "Rented" and cannot be rented by anyone else 
    /// @param _vehicleName is the name of the vehicle that is to be rented 
    /// @param _startDate is the beginning day of the rental 
    /// @param _duration is the number of days that the vehicle is to be rented. the end date is derived from this number
    function rentVehicle(string memory _vehicleName, uint _startDate, uint _duration) public payable isAvailable(_vehicleName) {
        require(msg.value == deposit, "You must pay the full deposit");
        uint length = _duration * 86400;
        vehicles[_vehicleName].startDate = _startDate;
        vehicles[_vehicleName].endDate = _startDate + length;
        vehicles[_vehicleName].isRented = true;
        vehicles[_vehicleName].finalPrice = vehicles[_vehicleName].dailyPrice * vehicles[_vehicleName].duration;
        vehicleAndRenter[_vehicleName] = msg.sender;
    }

    ///@notice Renter calls this function when physically returning the vehicle to calculate full amount owed
    /// @dev Late fee's are added to the final price for each day that the vehicle is late 
    function rentalVehicleFinalPrice(string memory _vehicleName) public returns(uint) {
        require(msg.sender == vehicleAndRenter[_vehicleName]);
        if (block.timestamp > vehicles[_vehicleName].endDate) {
            uint addedFee = ((block.timestamp - vehicles[_vehicleName].endDate) / 86400) * lateFeePerDay;
            vehicles[_vehicleName].finalPrice += addedFee;
        }
        vehicles[_vehicleName].checkedPrice = true;
        return vehicles[_vehicleName].finalPrice;

    }

    /// @notice Renter pays for and returns the vehicle and receives deposit back 
    /// @dev Renter returns the vehicle officially only after he/she runs the final price function 
    /// @dev Rented vehicle gets reset and is available for the next renter
    /// @dev Renter is sent .20 by way of the 'deposit' state variable which indicates the price of a deposit
    function returnVehicle(string memory _vehicleName) public payable {
        require(msg.sender == vehicleAndRenter[_vehicleName]);
        require(vehicles[_vehicleName].checkedPrice == true, "You must check the full price to assess late fees before completing the return");
        require(msg.value == vehicles[_vehicleName].finalPrice, "You must pay the full amount of the final price");
        payable(msg.sender).transfer(deposit);

        vehicles[_vehicleName].duration = 0;
        vehicles[_vehicleName].startDate = 0;
        vehicles[_vehicleName].endDate = 0;
        vehicles[_vehicleName].isRented = false;
        vehicles[_vehicleName].finalPrice = 0;
        vehicles[_vehicleName].checkedPrice = false;
    }

    /// @notice Only the owenr of the rental business is able to withdraw all funds from the contract
    function ownerWithdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}
