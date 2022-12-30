// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import {Script} from 'forge-std/Script.sol';

// import {Greeter} from "src/Greeter.sol";
// import {PrivateModule} from "src/PrivateModule.sol";
import {Button} from "src/Button.sol";

/// @notice A very simple deployment script
contract Deploy is Script {

  /// @notice The main script entrypoint
  function run() external {
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    vm.startBroadcast(deployerPrivateKey);
    Button button = new Button();
    vm.stopBroadcast();
  }
}