require("@nomicfoundation/hardhat-toolbox");
let secret = require("./secret");

require("@semaphore-protocol/hardhat")

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.4",
  networks: {
    goerli: {
      url: secret.goerli,
      accounts: [secret.key],
      gas: 35000000,
      gasPrice: 8000000000
    }
    },
  allowUnlimitedContractSize: true
}

