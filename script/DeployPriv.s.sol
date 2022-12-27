// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import {Script} from 'forge-std/Script.sol';

// import {Greeter} from "src/Greeter.sol";
import {PrivModule} from "src/PrivModule.sol";
import "@semaphore-protocol/contracts/Semaphore.sol";
import "@semaphore-protocol/contracts/interfaces/ISemaphore.sol";

/// @notice A very simple deployment script
contract Deploy is Script {

  /// @notice The main script entrypoint
  function run() external {
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    vm.startBroadcast(deployerPrivateKey);
    // vm.startBroadcast(0x0ACBa2baA02F59D8a3d738d97008f909fB92e9FB);
    // deploy new semaphore 
    ISemaphore.Verifier[] memory verifiers = new ISemaphore.Verifier[](1);
    verifiers[0] = ISemaphore.Verifier({merkleTreeDepth: 20, contractAddress: address(0x2a96c5696F85e3d2aa918496806B5c5a4D93E099)});
    Semaphore semaphore = new Semaphore(verifiers);

    // deploy private module
    address owner = 0x0ACBa2baA02F59D8a3d738d97008f909fB92e9FB; 
    address payable avatar = payable(0xC3ACf93b1AAA0c65ffd484d768576F4ce106eB4f);
    address payable target = payable(0xC3ACf93b1AAA0c65ffd484d768576F4ce106eB4f);
    PrivModule module = new PrivModule(owner, avatar, target, address(semaphore));
    vm.stopBroadcast();
  }
}