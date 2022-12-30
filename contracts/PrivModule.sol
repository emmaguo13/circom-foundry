pragma solidity ^0.8.0;

import "@gnosis.pm/zodiac/contracts/core/Module.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@semaphore-protocol/contracts/interfaces/ISemaphore.sol";
import {GnosisSafe} from "@gnosis.pm/safe-contracts/contracts/GnosisSafe.sol";

contract PrivModule is Module, ReentrancyGuard {
    struct Identity {
        uint256 id;
        uint256 identityCommitment;
        bytes32 username;
    }

    ISemaphore public semaphore;
    GnosisSafe public safe;

    uint256 public groupId;
    uint256 threshold;

    // TODO: might not need owners
    address[] public owners;
    Identity[] public identities;

    // maps address to whether or not they can be added as a member
    // only true if address is in owners set, and also if it has not already been added
    mapping(address => bool) possibleMember;
    mapping(address => bool) isOwner;

    event NewTxn();
    event NewUser(uint256 identityCommitment, bytes32 username);
    event ZkSigModuleSetup(
        address indexed initiator,
        address indexed owner,
        address indexed avatar,
        address target
    );

    event DebugGroup(address sender);

    error SignerAddFailed();
    error GroupCreateFailed();

    /// @param _owner Address of the  owner
    /// @param _avatar Address of the avatar (e.g. a Safe) basically thing executing the functions (relayer)
    /// @param _target Address of the contract that will call exec function - PASS TRANSACTIONS TO
    /// @param _semaphore Address of the semaphore contract
    constructor(
        address _owner,
        address payable _avatar,
        address payable _target,
        address _semaphore,
        uint256 _groupId
    ) 
    {
        bytes memory initParams = abi.encode(_owner, _avatar, _target);

        semaphore = ISemaphore(_semaphore);
        safe = GnosisSafe(_avatar);
        setAllowedOwners();
        threshold = safe.getThreshold();

        groupId = _groupId;

        setUp(initParams);
    }

    function setUp(bytes memory initParams) public override {
        (address _owner, address _avatar, address _target) = abi.decode(
            initParams,
            (address, address, address)
        );
        __Ownable_init();

        require(_avatar != address(0), "Avatar can not be zero address");
        require(_target != address(0), "Target can not be zero address");
        setAvatar(_avatar);
        setTarget(_target);

        transferOwnership(_owner);

        emit ZkSigModuleSetup(msg.sender, _owner, _avatar, _target);
    }

    function setAllowedOwners() internal {
        owners = safe.getOwners();
        uint256 len = owners.length;
        for (uint256 i = 0; i < len; i++) {
            possibleMember[owners[i]] = true;
            isOwner[owners[i]] = true;
        }
    }

    /* returns number of needed signers, to be called by frontend */
    function getThreshold() external returns (uint256) {
        return threshold;
    }

    // function getOwners() external returns (address[] memory) {
    //     return owners;
    // }

    // everytime you create a new transaction, you create a new group
    function newGroup()
        external
    {
        if (isOwner[msg.sender] == true) {
            semaphore.createGroup(groupId, 20, 0, address(this));
            // semaphore.createGroup(groupId, 20, 0, address(this));
            emit DebugGroup(msg.sender);
            // add all of the safe owners to the newly created group
            uint256 len = identities.length;
            for (uint256 i = 0; i < len; i++) {
                // TODO: *
                uint256 id = identities[i].identityCommitment;
                bytes32 user = identities[i].username;
                semaphore.addMember(groupId, id);
                // emit NewUser(id, user);
            }
            groupId++;
        } else {
            revert GroupCreateFailed();
        }
    }

    function joinAsSigner(uint256 identityCommitment, bytes32 username)
        external
    {
        // check if address is from owners
        if (possibleMember[msg.sender] == true) {
            // semaphore.addMember(groupId, identityCommitment);
            identities.push(Identity(identities.length, identityCommitment, username));
            emit NewUser(identityCommitment, username);
            
            // prevent user from adding themselves again
            possibleMember[msg.sender] = false;
        } else {
            revert SignerAddFailed();
        }
    }

    /// @dev Executes a transaction initated by the AMB
    /// @param to Target of the transaction that should be executed
    /// @param value Wei value of the transaction that should be executed
    /// @param data Data of the transaction that should be executed
    /// @param operation Operation (Call or Delegatecall) of the transaction that should be executed
    /// @param id GroupId of the group that corresponds to this transaction
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
        uint256 id,
        uint256[] memory merkleTreeRoots,
        uint256[] memory nullifierHashes,
        uint256[8][] calldata proofs,
        bytes32[] memory votes
    ) public {
        // by the time we have all of this, the threshold is basically met
        // TODO: check if there are enough VALID sigs
        uint256 merkleRootLen = merkleTreeRoots.length;
        uint256 nullifierLen = nullifierHashes.length;
        uint256 proofLen = proofs.length;
        uint256 votesLen = votes.length;

        require(
            merkleRootLen == nullifierLen,
            "wrong num of merkle roots/nuls"
        );
        require(nullifierLen == proofLen, "wrong num of proofs/nuls");
        require(proofLen == votesLen, "wrong num of merkle proofs/votes");
        require(merkleRootLen >= threshold, "threshold not met");

        for (uint256 i = 0; i < votesLen; i++) {
            require(uint256(votes[i]) == id, "wrong_vote");
            semaphore.verifyProof(
                id,
                merkleTreeRoots[i],
                votes[i],
                nullifierHashes[i],
                groupId - 1,
                proofs[i]
            );
        }

        require(exec(to, value, data, operation), "Module transaction failed");
        emit NewTxn();
    }
}
