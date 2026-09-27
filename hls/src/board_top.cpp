// board_top.cpp - board-ready wrapper of the AFDM modulator for the Zynq PS.
//
// Interfaces (what the ARM processor sees):
//   in, out : AXI master ports that read / write N words in DDR memory
//   control : AXI-Lite registers (start, done, and the two buffer addresses)
// Word format: one complex sample per 32-bit word, raw fixed-point values
// sign-extended to 16 bits: real part in bits 15..0, imaginary in 31..16.
// Requires WD <= 16.
#include <ap_int.h>
#include "blocks.h"

typedef ap_uint<32> word_t;

static cdata unpack(word_t w) {
    ap_int<16> re = w.range(15, 0);
    ap_int<16> im = w.range(31, 16);
    cdata c;
    c.re.range(WD - 1, 0) = re.range(WD - 1, 0);
    c.im.range(WD - 1, 0) = im.range(WD - 1, 0);
    return c;
}

static word_t pack(const cdata &c) {
    ap_int<WD> re, im;
    re.range(WD - 1, 0) = c.re.range(WD - 1, 0);
    im.range(WD - 1, 0) = c.im.range(WD - 1, 0);
    ap_int<16> re16 = re, im16 = im;             // sign extension
    word_t w;
    w.range(15, 0)  = re16.range(15, 0);
    w.range(31, 16) = im16.range(15, 0);
    return w;
}

void afdm_mod_top(const word_t in[N], word_t out[N]) {
#pragma HLS INTERFACE mode=m_axi port=in  offset=slave bundle=gmem depth=256
#pragma HLS INTERFACE mode=m_axi port=out offset=slave bundle=gmem depth=256
#pragma HLS INTERFACE mode=s_axilite port=return
    cdata x[N], s[N];
read_in:
    for (int n = 0; n < N; n++) x[n] = unpack(in[n]);
    afdm_mod(x, s);
write_out:
    for (int n = 0; n < N; n++) out[n] = pack(s[n]);
}
