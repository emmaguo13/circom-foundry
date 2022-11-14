pragma circom 2.0.2;

include "../lib/circom-ecdsa/circuits/secp256k1.circom";
include "../lib/circom-ecdsa/circuits/ecdsa.circom";
include "../lib/circom-ecdsa/circuits/bigint.circom";
include "../lib/circom-ecdsa/circuits/bigint_func.circom";
include "../lib/circom-ecdsa/circuits/secp256k1_func.circom";

// if s == 0 returns [in[0], in[1]]
// if s == 1 returns [in[1], in[0]]
template Ecrecover(n, k) {
    signal input h[k];
    signal input v[k];
    signal input r[k];
    signal input s[k];
    signal output pubkey[k];

    // make sure we get the right r, and not R

    // inverse modulo r
    var order[100] = get_secp256k1_order(n, k);
    component inv_r = BigModInv(n, k);
    for (var idx = 0; idx < k; idx++) {
        inv_r.in[idx] <== r[idx];
        inv_r.p[idx] <== order[idx];
    }

    // s.G
    component s_g_mult = ECDSAPrivToPub(n, k);
    for (var idx = 0; idx < k; idx++) {
        s_g_mult.privkey[idx] <== s[idx];
    }

    // r.(s.G)
    component scalar_mul = Secp256k1ScalarMult(n, k);
    for (var idx = 0; idx < k; idx++) {
        scalar_mul.scalar[idx] <== r[idx];
        scalar_mul.point[0][idx] <== s_g_mult.pubkey[0][idx];
        scalar_mul.point[1][idx] <== s_g_mult.pubkey[1][idx];
    }

    // h.G
    component h_g_mult = ECDSAPrivToPub(n, k);
    for (var idx = 0; idx < k; idx++) {
        h_g_mult.privkey[idx] <== h[idx];
    }

    // The v can be either 27 (0x1b) or 28 (0x1c)

    // template BigIsEqual(k){
    // signal input in[2][k];
    // signal output out;

    // *****************

    // negate r.s.G point to (x, -y)
    component sub = BigSub(n, k);
    for (var idx = 0; idx < k; idx++) {
        sub.a[idx] <== 0;
        sub.b[idx] <== scalar_mul.out[1][idx];
    }

    // deal with underflow after sub

    // h.G - r.s.G
    r.s.G - h.G
    component add = Secp256k1AddUnequal(n, k);
    for (var idx = 0; idx < k; idx++) {
        add.a[0][idx] <== h_g_mult.pubkey[0][idx];
        add.a[1][idx] <== h_g_mult.pubkey[1][idx];
        add.b[0][idx] <== scalar_mul.out[0][idx];
        add.b[1][idx] <== sub.out[idx];
    }

     // *****************

    // r^-1 . (h.G - r.s.G)
    component inv_scalar_mul = Secp256k1ScalarMult(n, k);
    for (var idx = 0; idx < k; idx++) {
        inv_scalar_mul.scalar[idx] <== inv_r.out[idx];
        inv_scalar_mul.point[0][idx] <== s_g_mult.pubkey[0][idx];
        inv_scalar_mul.point[1][idx] <== s_g_mult.pubkey[1][idx];
    }

    // do check for v
    // also how do we actually return the public key

    for (var idx = 0; idx < k; idx++) {
        pubkey[idx] << inv_scalar_mul.
        inv_scalar_mul.scalar[idx] <== inv_r.out[idx];
        inv_scalar_mul.point[0][idx] <== s_g_mult.pubkey[0][idx];
        inv_scalar_mul.point[1][idx] <== s_g_mult.pubkey[1][idx];
    }



}

component main {public [in, s]} = DualMux();