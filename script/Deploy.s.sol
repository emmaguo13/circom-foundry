// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import {Script} from 'forge-std/Script.sol';

// import {Greeter} from "src/Greeter.sol";
import {PrivateModule} from "src/PrivateModule.sol";

/// @notice A very simple deployment script
contract Deploy is Script {

  /// @notice The main script entrypoint
  function run() external {
    vm.startBroadcast(0x0ACBa2baA02F59D8a3d738d97008f909fB92e9FB);
    PrivateModule privModule = new PrivateModule(address(0x0ACBa2baA02F59D8a3d738d97008f909fB92e9FB), payable(address(0xC3ACf93b1AAA0c65ffd484d768576F4ce106eB4f)), payable(address(0xC3ACf93b1AAA0c65ffd484d768576F4ce106eB4f)), address(0x5259d32659F1806ccAfcE593ED5a89eBAb85262f), 28);
    vm.stopBroadcast();
  }
}