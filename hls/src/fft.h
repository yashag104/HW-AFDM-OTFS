// fft.h - radix-2 DIT FFT, bit-exact with matlab/fixed/fft_fx.m.
//
// Stage s (0-based), butterfly on a (top) and b (bottom), twiddle w:
//   t  = b * w                  exact (acc_t)
//   a' = round((a + t) * g)     g = 1/2 when s is even, else 1
//   b' = round((a - t) * g)
// Scaling every other stage gives 2^(-LOG2L/2) = 1/sqrt(L): a unitary transform.
//
// Two architectures with identical arithmetic (select with -DFFT_ARCH=0/1):
//   0 : in place, one buffer, one butterfly every 2 cycles (II = 2)  - small
//   1 : ping-pong stage buffers, one butterfly per cycle (II = 1)     - fast,
//       twice the buffer memory
#pragma once
#include "types.h"

#ifndef FFT_ARCH
#define FFT_ARCH 0
#endif

// Complex multiply of data by a ROM value, full precision.
static inline void cmul(const cdata &x, const crom &w, acc_t &re, acc_t &im) {
    re = acc_t(x.re * w.re) - acc_t(x.im * w.im);
    im = acc_t(x.re * w.im) + acc_t(x.im * w.re);
}

// One butterfly; the outputs are rounded and saturated to data_t on assignment.
static inline void butterfly(const cdata &a, const cdata &b, const crom &w, bool scale,
                             cdata &top, cdata &bot) {
    acc_t tre, tim;
    cmul(b, w, tre, tim);
    acc_t sre = a.re + tre, sim = a.im + tim;
    acc_t dre = a.re - tre, dim = a.im - tim;
    if (scale) { sre >>= 1; sim >>= 1; dre >>= 1; dim >>= 1; }   // exact: acc_t has a spare bit
    top.re = sre;  top.im = sim;
    bot.re = dre;  bot.im = dim;
}

// Bit-reversed index of i (LOG2L bits).
template <int LOG2L>
static inline int bitrev(int i) {
    int r = 0;
    for (int bit = 0; bit < LOG2L; bit++) r |= ((i >> bit) & 1) << (LOG2L - 1 - bit);
    return r;
}

// FFT of x in place (length L = 2^LOG2L). tw holds L/2 twiddles:
// exp(-j 2 pi k / L) for a forward FFT, exp(+j 2 pi k / L) for an inverse FFT.
template <int L, int LOG2L>
void fft(cdata x[L], const crom tw[L / 2]) {
#if FFT_ARCH == 0
    cdata tmp[L];
reorder:
    for (int i = 0; i < L; i++) {
#pragma HLS PIPELINE II=1
        tmp[bitrev<LOG2L>(i)] = x[i];
    }
stages:
    for (int s = 0; s < LOG2L; s++) {
        const int half = 1 << s;                 // butterfly distance
    butterflies:
        for (int i = 0; i < L / 2; i++) {
// Two reads and two writes of tmp per butterfly on a dual-port RAM -> II = 2.
// Butterflies of one stage touch disjoint elements (no inter-iteration dependence).
#pragma HLS PIPELINE II=2
#pragma HLS DEPENDENCE variable=tmp type=inter false
            const int k  = i & (half - 1);       // position inside the group
            const int ia = ((i >> s) << (s + 1)) + k;
            const int ib = ia + half;
            butterfly(tmp[ia], tmp[ib], tw[k * (L / (2 * half))], (s % 2) == 0, tmp[ia], tmp[ib]);
        }
    }
copy_out:
    for (int i = 0; i < L; i++) {
#pragma HLS PIPELINE II=1
        x[i] = tmp[i];
    }
#else
    cdata buf[2][L];                             // stage s reads buf[s&1], writes buf[(s+1)&1]
#pragma HLS ARRAY_PARTITION variable=buf dim=1 complete
reorder:
    for (int i = 0; i < L; i++) {
#pragma HLS PIPELINE II=1
        buf[0][bitrev<LOG2L>(i)] = x[i];
    }
stages:
    for (int s = 0; s < LOG2L; s++) {
        const int half = 1 << s;
    butterflies:
        for (int i = 0; i < L / 2; i++) {
// Two reads from one buffer and two writes to the other -> II = 1 on dual-port RAMs.
#pragma HLS PIPELINE II=1
#pragma HLS DEPENDENCE variable=buf type=inter false
            const int k  = i & (half - 1);
            const int ia = ((i >> s) << (s + 1)) + k;
            const int ib = ia + half;
            const int src = s & 1, dst = (s + 1) & 1;
            butterfly(buf[src][ia], buf[src][ib], tw[k * (L / (2 * half))], (s % 2) == 0,
                      buf[dst][ia], buf[dst][ib]);
        }
    }
copy_out:
    for (int i = 0; i < L; i++) {
#pragma HLS PIPELINE II=1
        x[i] = buf[LOG2L & 1][i];
    }
#endif
}
