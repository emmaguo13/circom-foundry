// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

// import {ZkSigModule} from "src/ZkSigModule.sol";
import {PrivateModule} from "src/PrivateModule.sol";
// import {MockSafe} from "src/MockSafe.sol";
// import {Button} from "src/Button.sol";

contract PrivateTest is Test {
    using stdStorage for StdStorage;

    PrivateModule module;
    // MockSafe mockSafe;
    // Button button;

    event sigEmitted();
    event ThresholdEmitted(uint256 threshold);
    event NonceEmitted(bytes32 nonce);

    function setUp() external {
        /*
         /// @param _owner Address of the  owner
        /// @param _avatar Address of the avatar (e.g. a Safe) basically thing executing the functions (relayer)
        /// @param _target Address of the contract that will call exec function - PASS TRANSACTIONS TO
        /// @param _semaphore Address of the semaphore contract
        /// @param _groupId semaphore groupId
        */
        address owner = 0x0ACBa2baA02F59D8a3d738d97008f909fB92e9FB; 
        // this was the old mock safe 
        // address avatar = 0xbfd0495c60772f42aa70a9be73af67b26678a530; 
        // address of our actual safe 
        address payable avatar = payable(0xC3ACf93b1AAA0c65ffd484d768576F4ce106eB4f);
        address payable target = payable(0xC3ACf93b1AAA0c65ffd484d768576F4ce106eB4f);
        address semaphore = 0x5259d32659F1806ccAfcE593ED5a89eBAb85262f;
        uint256 groupId = 31;

        module = new PrivateModule(owner, avatar, target, semaphore, groupId);
    }

    // VM Cheatcodes can be found in ./lib/forge-std/src/Vm.sol
    // Or at https://github.com/foundry-rs/forge-std
    function testWorking() external {
        // slither-disable-next-line reentrancy-events,reentrancy-benign
        uint256 hi = 1;
        assertEq(hi, 1);
    }

    function testThreshold() external {
        uint256 threshold = module.getThreshold();
        assertEq(threshold, 1);
        emit ThresholdEmitted(threshold);
    }

    function testNonceBytes32() external { 
        bytes32 vote = 0x0000000000000000000000000000000000000000000000000000000000000001;
        assertEq(uint256(vote), 1);
    }

    // function testExecute() external {
    //     zkSig.executeTransaction(
    //         address(button),
    //         0,
    //         abi.encodePacked(bytes4(keccak256("pushButton()"))),
    //         Enum.Operation.Call
    //     );
    // }

}
