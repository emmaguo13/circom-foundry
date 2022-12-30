pragma solidity ^0.8.6;

contract Button {
    event ButtonPushed(address pusher, uint256 pushes);
    
    uint256 public pushes;
    
    function pushButton() public {
        pushes++;
        emit ButtonPushed(msg.sender, pushes);
    }
}