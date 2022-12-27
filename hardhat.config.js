require("@nomicfoundation/hardhat-toolbox");
let secret = require("./secret");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.4",
  networks: {
    hardhat: {
      forking: {
        url: secret.goerli,
        accounts: [secret.key],
        gas: 3500000,
        gasPrice: 8000000000
      }
    },
  },
  allowUnlimitedContractSize: true
}

