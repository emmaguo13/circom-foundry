pragma solidity ^0.8.0;

import "zodiac/core/Module.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@semaphore-protocol/contracts/interfaces/ISemaphore.sol";
import "./MerkleTreeWithHistory.sol";

contract PrivateModule is Module, ReentrancyGuard {

  ISemaphore public semaphore;

  uint256 groupId;
  mapping(uint256 => bytes32) users;

  event NewTxn(bytes32 data);
  event NewUser(uint256 identityCommitment, bytes32 username);
  event ZkSigModuleSetup(
    address indexed initiator,
    address indexed owner,
    address indexed avatar,
    address target
  );

  /// @param _owner Address of the  owner
  /// @param _avatar Address of the avatar (e.g. a Safe) basically thing executing the functions (relayer)
  /// @param _target Address of the contract that will call exec function - PASS TRANSACTIONS TO
  /// @param _semaphore Address of the semaphore contract
  /// @param _groupId semaphore groupId
  constructor(
    address _owner,
    address _avatar,
    address _target,
    address _semaphore,
    uint256 _groupId
  )  {

    bytes memory initParams = abi.encode(
      _owner,
      _avatar,
      _target
    );

    semaphore = ISemaphore(semaphoreAddress);
    groupId = _groupId;
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

  function joinAsSigner(uint256 identityCommitment, bytes32 username) external {
        semaphore.addMember(groupId, identityCommitment);

        users[identityCommitment] = username;

        emit NewUser(identityCommitment, username);
  }

  /// @dev Executes a transaction initated by the AMB
  /// @param to Target of the transaction that should be executed
  /// @param value Wei value of the transaction that should be executed
  /// @param data Data of the transaction that should be executed
  /// @param operation Operation (Call or Delegatecall) of the transaction that should be executed
  /// @param merkleTreeRoot 
  /// @param nullifierHash
  /// @param proof We pass in the proof, verify it, and then execute 
  // TODO: first test: just one user, one proof
  function executeTransaction(
    address to, // this is the target address, eg if you want the txn to push a button, this is the button
    // for us, don't we want the target to be anything?
    uint256 value,
    bytes memory data,
    Enum.Operation operation,
    uint256 merkleTreeRoot,
    uint256 nullifierHash,
    uint256[8] calldata proof
  ) public {
    semaphore.verifyProof(groupId, merkleTreeRoot, greeting, nullifierHash, groupId, proof);

    require(exec(to, value, data, operation), "Module transaction failed");
    emit NewTxn(data);
  }
}