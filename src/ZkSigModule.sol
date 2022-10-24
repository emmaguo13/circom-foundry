pragma solidity ^0.8.0;

import "zodiac/core/Module.sol";
// import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./MerkleTreeWithHistory.sol";

interface IVerifier {
  function verifyProof(bytes memory _proof, uint256[6] memory _input) external returns (bool);
}

contract ZkSigModule is Module, MerkleTreeWithHistory, ReentrancyGuard{

  // We might want an interface for ZkSig, not sure what the interface would be used for
  // Most likely not since the bridge zodiac module needs an AMB to do cross chain sending, the interface
  // represents a different AMB instance.

  event ZkSigModuleSetup(
    address indexed initiator,
    address indexed owner,
    address indexed avatar,
    address target
  );
  event AddSigner(bytes32 indexed commitment, uint32 leafIndex, uint256 timestamp);

  address public controller;
  bytes32 public chainId;

  IVerifier public immutable verifier;

  mapping(bytes32 => bool) public nullifierHashes;
  mapping(bytes32 => bool) public commitments;

  /// @param _owner Address of the  owner
  /// @param _avatar Address of the avatar (e.g. a Safe) basically thing executing the functions (relayer)
  /// @param _target Address of the contract that will call exec function - PASS TRANSACTIONS TO
  /// @param _chainId Address of the authorized chainId from which owner can initiate transactions
  constructor(
    address _owner,
    address _avatar,
    address _target,
    //ZkSign _zkSign,
    bytes32 _chainId,
    address _verifier,
    // TODO: deal with hasher stuff
    address _hasher,
    uint32 _merkleTreeHeight

  )  MerkleTreeWithHistory(_merkleTreeHeight, IHasher(_hasher)) {

    bytes memory initParams = abi.encode(
      _owner,
      _avatar,
      _target,
      _chainId
    );

    verifier = IVerifier(_verifier);

    setUp(initParams);
  }

  function setUp(bytes memory initParams) public override initializer {
    (
      address _owner,
      address _avatar,
      address _target,
      bytes32 _chainId
    ) = abi.decode(
        initParams,
        (address, address, address, bytes32)
      );
    __Ownable_init();

    require(_avatar != address(0), "Avatar can not be zero address");
    require(_target != address(0), "Target can not be zero address");
    setAvatar(_owner);
    setTarget(_owner);
    chainId = _chainId;

    transferOwnership(_owner);

    emit ZkSigModuleSetup(msg.sender, _owner, _avatar, _target);
  }

  /**
    @dev add a signer to the merkle tree
    @param _commitment the note commitment, which is PedersenHash(nullifier, signatory address)
  */
  function addSigner(bytes32 _commitment) external nonReentrant {
    require(!commitments[_commitment], "The commitment has been submitted");

    uint32 insertedIndex = _insert(_commitment);
    commitments[_commitment] = true;

    emit AddSigner(_commitment, insertedIndex, block.timestamp);
  }

  // function verifySignatures(
  //   bytes[] calldata _proofs,
  //   bytes32 _root,
  //   bytes32[] _nullifierHashes,
  //   address payable _recipient, // not sure if i need
  //   address payable _relayer,
  //   uint256 _fee, // no ?
  //   uint256 _refund // no ?
  // ) internal {
  //   uint32 nullLens = _nullifierHashes.length;
  //   require(nullLens == _proofs.length, "Num proofs not matching nullifiers");
  //   // not sure where isKnownRoot imported from
  //   require(isKnownRoot(_root), "Cannot find your merkle root");
  //   for (uint32 i = 0; i < nullLens; i++) {
  //     require(!nullifierHashes[_nullifierHashes[i]], "The note has been already spent");
  //     require(
  //     verifier.verifyProof(
  //       _proofs[i],
  //       [uint256(_root), uint256(_nullifierHashes[i]), uint256(_recipient), uint256(_relayer), _fee, _refund]
  //     ),
  //     "Invalid withdraw proof"
  //      );
  //     nullifierHashes[_nullifierHashes[i]] = true;
  //   }
     //_processWithdraw(_recipient, _relayer, _fee, _refund);
    //emit Withdrawal(_recipient, _nullifierHash, _relayer, _fee);
  //}

  /// @dev Executes a transaction initated by the AMB
  /// @param to Target of the transaction that should be executed
  /// @param value Wei value of the transaction that should be executed
  /// @param data Data of the transaction that should be executed
  /// @param operation Operation (Call or Delegatecall) of the transaction that should be executed
  
  // this executeTransaction function can take in any input, so we will be doing our checks here
  function executeTransaction(
    address to, // this is the target address, eg if you want the txn to push a button, this is the button
    // for us, don't we want the target to be anything?
    uint256 value,
    bytes memory data,
    Enum.Operation operation
  ) public {
    require(exec(to, value, data, operation), "Module transaction failed");
  }

  // might want a set target function, for now, lets do simple transfers

}