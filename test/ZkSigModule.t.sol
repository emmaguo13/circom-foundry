// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import {ZkSigModule} from "src/ZkSigModule.sol";
import {MockSafe} from "src/MockSafe.sol";
import {Button} from "src/Button.sol";
import { Enum } from "@gnosis.pm/safe-contracts/contracts/common/Enum.sol";

contract ZkSigTest is Test {
    using stdStorage for StdStorage;

    ZkSigModule zkSig;
    MockSafe mockSafe;
    Button button;

    event sigEmitted();

    function setUp() external {
        /*
        address _owner,
        address _avatar,
        address _target,
        //ZkSign _zkSign,
        bytes32 _chainId,
        IVerifier _verifier,
        IHasher _hasher,
        uint32 _merkleTreeHeight
        */
        address hasherAddress = 0x83584f83f26aF4eDDA9CBe8C730bc87C364b28fe; // Tornado Cashes' Mimc hasher - don't need unique right?
        address verifierAddress = 0xce172ce1F20EC0B3728c9965470eaf994A03557A; // deploy your own verifier later.
        zkSig = new ZkSigModule(msg.sender, 0x0000000000000000000000000000000000000001, 0x0000000000000000000000000000000000000001, 0, verifierAddress, hasherAddress, 4);
        mockSafe = new MockSafe();
        button = new Button();
    }

    // VM Cheatcodes can be found in ./lib/forge-std/src/Vm.sol
    // Or at https://github.com/foundry-rs/forge-std
    function testSetZkSig() external {
        // slither-disable-next-line reentrancy-events,reentrancy-benign
        uint256 hi = 1;
        assertEq(hi, 1);
        // setUp();

        zkSig.executeTransaction(
            address(button),
            0,
            abi.encodePacked(bytes4(keccak256("pushButton()"))),
            Enum.Operation.Call
        );

//         function executeTransaction(
//     address to, // this is the target address, eg if you want the txn to push a button, this is the button
//     // for us, don't we want the target to be anything?
//     uint256 value,
//     bytes memory data,
//     Enum.Operation operation
//   ) public {
//     require(exec(to, value, data, operation), "Module transaction failed");
//   }

//   button,
//         0,
//         abi.encodePacked(bytes4(keccak256("pushButton()"))),
//         Enum.Operation.Call

//         zkSig.executeTransaction(
//             0x0000000000000000000000000000000000000001,
//             2，
//             "",
            
//         )

        // i think these tests should be in js
        //bytes32 indexed comm = pedersenHash(msg.sender + 0x1)
        //zkSig.addSigner();

        // // Expect the GMEverybodyGM event to be fired
        // vm.expectEmit(true, true, true, true);
        // emit sigEmitted();
        // // slither-disable-next-line unused-return
        // greeter.gm("gm gm");

        // // Expect the gm() call to revert
        // vm.expectRevert(abi.encodeWithSignature("BadGm()"));
        // // slither-disable-next-line unused-return
        // greeter.gm("gm");

        // // We can read slots directly
        // uint256 slot = stdstore.target(address(greeter)).sig(greeter.owner.selector).find();
        // assertEq(slot, 1);
        // bytes32 owner = vm.load(address(greeter), bytes32(slot));
        // assertEq(address(this), address(uint160(uint256(owner))));
    }
}
