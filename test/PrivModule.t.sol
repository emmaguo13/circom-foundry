// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import {PrivModule} from "src/PrivModule.sol";
import {Semaphore} from "@semaphore-protocol/contracts/Semaphore.sol";
import "zodiac/core/Module.sol";

contract PrivTest is Test {
    using stdStorage for StdStorage;

    PrivModule module;
    Semaphore semaphore;

    address sender = address(0x0ACBa2baA02F59D8a3d738d97008f909fB92e9FB);

    event sigEmitted();
    event ThresholdEmitted(uint256 threshold);
    event NonceEmitted(bytes32 nonce);

    function setUp() external {

        address owner = 0x0ACBa2baA02F59D8a3d738d97008f909fB92e9FB; 
        address payable avatar = payable(0xC3ACf93b1AAA0c65ffd484d768576F4ce106eB4f);
        address payable target = payable(0xC3ACf93b1AAA0c65ffd484d768576F4ce106eB4f);
        // address semaphore = 0x5259d32659F1806ccAfcE593ED5a89eBAb85262f;

        Verifier[] memory verifiers = new Verifier[](1);
        verifiers[0] = Verifier({merkleTreeDepth: 20, contractAddress: address(0x2a96c5696F85e3d2aa918496806B5c5a4D93E099)});
        semaphore = new Semaphore(verifiers);

        module = new PrivModule(owner, avatar, target, address(semaphore));
    }

    // VM Cheatcodes can be found in ./lib/forge-std/src/Vm.sol
    // Or at https://github.com/foundry-rs/forge-std
    function testWorking() external {
        // slither-disable-next-line reentrancy-events,reentrancy-benign
        uint256 hi = 1;
        assertEq(hi, 1);
    }

    function testThreshold() external {
        uint256 threshold = module.getThreshold();
        assertEq(threshold, 1);
        emit ThresholdEmitted(threshold);
    }

    function testNewGroup() external {
        uint256 groupId = module.groupId();
        vm.prank(sender);
        module.newGroup();
        assertEq(module.groupId(), groupId + 1);
    }

    function testJoinSigner() external {
        bytes32 user = 0x0000000000000000000000000000000000000000000000000000000000000000;
        uint256 id = 20183259997866222879589925831142697062020548183248584087151364292929346471340;

        vm.prank(sender);

        module.joinAsSigner(id, user);

        uint256 idFromArray;
        uint256 identityFromArray;
        bytes32 usernameFromArray;

        // get the newly joined signer
        (idFromArray, identityFromArray, usernameFromArray) = module.identities(0);

        assertEq(identityFromArray, id);
        assertEq(usernameFromArray, user);

        // vm.expectEmit(id, user);
    }

    function testExecute() external {
        address to = address(0xC3ACf93b1AAA0c65ffd484d768576F4ce106eB4f);
        uint256 value = 0;
        bytes memory data = abi.encodePacked('');
        Enum.Operation operation = Enum.Operation.Call;
        uint256 id = module.groupId();

        uint256[] memory merkleTreeRoots = new uint256[](1);

        merkleTreeRoots[0] = 4591141196456176864016915754547308561022255871897265820863602651731627419971;
    
        uint256[] memory nullifierHashes = new uint256[](1);
        nullifierHashes[0] =
            2623183898452010234004928810760845778301182165458782784055156900027930450068;

        uint256[8][] memory proofs = new uint256[8][](1);
        proofs[0] =
            [
                15082228044817502732539667749392315696461963041265415019527164656331473466925,
                10025323472904820886641259258654776098857513218637983877020561495623509275132,
                20943701449268585201870132928364517028435037697216364836543976532508469579947,
                20196322734005938692677220189773432867404957735761740617474786558302188490812,
                18608453172398675174908678797459461559496701600760736799811951413150293706142,
                14382591325781110174980591710154678889261509457306651181488501996237786115027,
                1675811793008655022663770832334432015046193122071528090239076896694793918228,
                17678590417784343246920695269286752809320878201559866912713252910363344203636
            ];

        bytes32[] memory votes = new bytes32[](1);
        votes[0] = bytes32(module.groupId());

        module.executeTransaction(
            to,
            value,
            data,
            operation,
            id,
            merkleTreeRoots,
            nullifierHashes,
            proofs,
            votes
        );
    }

}
