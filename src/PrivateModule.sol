pragma solidity ^0.8.0;

import "zodiac/core/Module.sol";
// import "zodiac/guard/BaseGuard.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@semaphore-protocol/contracts/interfaces/ISemaphore.sol";
// import "./MerkleTreeWithHistory.sol";
import {GnosisSafe} from "@gnosis.pm/safe-contracts/contracts/GnosisSafe.sol";

contract PrivateModule is Module, ReentrancyGuard {

  ISemaphore public semaphore;
  GnosisSafe public safe;

  uint256 groupId;
  uint256 threshold;

  // maps identity committment to username
  mapping(uint256 => bytes32) users;

  // maps address to whether or not they can be added as a member
  // only true if address is in owners set, and also if it has not already been added
  mapping(address => bool) possibleMember; 

  event NewTxn();
  event NewUser(uint256 identityCommitment, bytes32 username);
  event ZkSigModuleSetup(
    address indexed initiator,
    address indexed owner,
    address indexed avatar,
    address target
  );

  error SignerAddFailed();

  /// @param _owner Address of the  owner
  /// @param _avatar Address of the avatar (e.g. a Safe) basically thing executing the functions (relayer)
  /// @param _target Address of the contract that will call exec function - PASS TRANSACTIONS TO
  /// @param _semaphore Address of the semaphore contract
  /// @param _groupId semaphore groupId
  constructor(
    address _owner,
    address payable _avatar,
    address _target,
    address _semaphore,
    uint256 _groupId
  )  {

    bytes memory initParams = abi.encode(
      _owner,
      _avatar,
      _target
    );

    semaphore = ISemaphore(_semaphore);
    safe = GnosisSafe(_avatar);
    setAllowedOwners();
    groupId = _groupId;
    threshold = safe.getThreshold();
    semaphore.createGroup(groupId, 20, 0, address(this));

    setUp(initParams);
  }

  function setUp(bytes memory initParams) public override {
    (
      address _owner,
      address _avatar,
      address _target
    ) = abi.decode(
        initParams,
        (address, address, address)
      );
    __Ownable_init();

    require(_avatar != address(0), "Avatar can not be zero address");
    require(_target != address(0), "Target can not be zero address");
    setAvatar(_owner);
    setTarget(_owner);

    transferOwnership(_owner);

    emit ZkSigModuleSetup(msg.sender, _owner, _avatar, _target);
  }

  function setAllowedOwners() internal {
    address[] memory owners = safe.getOwners();
    uint256 len = owners.length;
    for (uint256 i = 0; i < len; i ++) {
      possibleMember[owners[i]] = true;
    }
  }

  /* returns number of needed signers, to be called by frontend */
  function getThreshold() external returns (uint256) {
    return threshold;
  }

  // joining as a signer is now not private 
  // TODO: what is the username supposed to be
  // TODO: error code for not being a part of owners ?
  function joinAsSigner(uint256 identityCommitment, bytes32 username) external {
    // check if address is from owners
    if (possibleMember[msg.sender] == true) {
      semaphore.addMember(groupId, identityCommitment);
      users[identityCommitment] = username;
      emit NewUser(identityCommitment, username);
    } else {
      revert SignerAddFailed();
    }
  }

  /// @dev Executes a transaction initated by the AMB
  /// @param to Target of the transaction that should be executed
  /// @param value Wei value of the transaction that should be executed
  /// @param data Data of the transaction that should be executed
  /// @param operation Operation (Call or Delegatecall) of the transaction that should be executed
  /// @param merkleTreeRoots merkle tree root
  /// @param nullifierHashes nullifier hash
  /// @param proofs We pass in the proof, verify it, and then execute 
  /// @param votes the vote on the given transaction

  function executeTransaction(
    address to, // this is the target address, eg if you want the txn to push a button, this is the button
    // for us, don't we want the target to be anything?
    uint256 value,
    bytes memory data,
    Enum.Operation operation,

    uint256[] memory merkleTreeRoots,
    uint256[] memory nullifierHashes,
    uint256[8][] memory proofs,
    bytes32[] memory votes
  ) public {

    // by the time we have all of this, the threshold is basically met
    // TODO: check if there are enough VALID sigs
    uint256 merkleRootLen = merkleTreeRoots.length;
    uint256 nullifierLen = nullifierHashes.length;
    uint256 proofLen = proofs.length;
    uint256 votesLen = votes.length;

    assert(merkleRootLen == nullifierLen);
    assert(nullifierLen == proofLen);
    assert(proofLen == votesLen);

    assert(merkleRootLen == threshold);

    for (uint256 i = 0; i < votesLen; i ++) {
      semaphore.verifyProof(groupId, merkleTreeRoots[i], votes[i], nullifierHashes[i], groupId, proofs[i]);
    }

    require(exec(to, value, data, operation), "Module transaction failed");
    emit NewTxn();
  }
}