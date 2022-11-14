pragma circom 2.0.2;

include "../lib/circom-ecdsa/circuits/ecdsa.circom";

// Verifies an ECDSA signature

component main {public [r, s, msghash, pubkey]} = ECDSAVerifyNoPubkeyCheck(64, 4);