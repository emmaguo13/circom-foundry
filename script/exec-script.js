const hre = require("hardhat");
const secret = require("../secret");
const circomlib = require("circomlibjs");

// import { poseidon_gencontract as poseidonContract } from "circomlibjs"
// import { Contract } from "ethers"

// const erc20 = require("../utils/erc20mintable.json");
// const poolABI = require("../utils/pool.json");

const chai = require("chai");
const { expect } = chai;
chai.use(require("chai-bignumber")(hre.ethers.BigNumber));

const convertToCurrencyDecimals = async (amount, decimals) => {
  return hre.ethers.utils.parseUnits(amount, decimals);
};

async function main() {
  const poseidonT3ABI = circomlib.poseidonContract.generateABI(2);
  const poseidonT3Bytecode = circomlib.poseidonContract.createCode(2);

  const [signer] = await hre.ethers.getSigners();

  const PoseidonLibT3Factory = new hre.ethers.ContractFactory(
    poseidonT3ABI,
    poseidonT3Bytecode,
    signer
  );
  const poseidonT3Lib = await PoseidonLibT3Factory.deploy();

  await poseidonT3Lib.deployed();

  console.log(
    `PoseidonT3 library has been deployed to: ${poseidonT3Lib.address}`
  );

  const IncrementalBinaryTreeLibFactory = await hre.ethers.getContractFactory(
    "IncrementalBinaryTree",
    {
      libraries: {
        PoseidonT3: poseidonT3Lib.address,
      },
    }
  );
  const incrementalBinaryTreeLib =
    await IncrementalBinaryTreeLibFactory.deploy();

  await incrementalBinaryTreeLib.deployed();

  console.log(
    `IncrementalBinaryTree library has been deployed to: ${incrementalBinaryTreeLib.address}`
  );

  // deploy sema contract
  const Semaphore = await hre.ethers.getContractFactory("@semaphore-protocol/contracts/Semaphore.sol:Semaphore", {
    libraries: {
      IncrementalBinaryTree: incrementalBinaryTreeLib.address,
    },
  });
  const verifierAddress = "0x2a96c5696F85e3d2aa918496806B5c5a4D93E099";
  const semaphore = await Semaphore.deploy([
    {
      merkleTreeDepth: 20,
      contractAddress: verifierAddress,
    },
  ]);
  await semaphore.deployed();

  console.log(`Semaphore contract has been deployed to: ${semaphore.address}`);

  // deploy priv module
  // const Module = await hre.ethers.getContractFactory("PrivModule");
  // const owner = "0x0ACBa2baA02F59D8a3d738d97008f909fB92e9FB";
  // const avatar = "0xC3ACf93b1AAA0c65ffd484d768576F4ce106eB4f";
  // const target = "0xC3ACf93b1AAA0c65ffd484d768576F4ce106eB4f";

  // const module = await Module.deploy(
  //   owner,
  //   avatar,
  //   target,
  //   semaphore.address,
  //   0,
  //   {
  //     gasLimit: 500000000
  //   }
  // );
  // await module.deployed();
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
