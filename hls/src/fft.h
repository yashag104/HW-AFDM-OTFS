// fft.h - radix-2 DIT FFT, bit-exact with matlab/fixed/fft_fx.m.
//
// Stage s (0-based), butterfly on a (top) and b (bottom), twiddle w:
//   t  = b * w                  exact (acc_t)
//   a' = round((a + t) * g)     g = 1/2 when s is even, else 1
//   b' = round((a - t) * g)
// Scaling every other stage gives 2^(-LOG2L/2) = 1/sqrt(L): a unitary transform.
#pragma once
#include "types.h"

// Complex multiply of data by a ROM value, full precision.
static inline void cmul(const cdata &x, const crom &w, acc_t &re, acc_t &im) {
    re = acc_t(x.re * w.re) - acc_t(x.im * w.im);
    im = acc_t(x.re * w.im) + acc_t(x.im * w.re);
}

// In-place FFT of x (length L = 2^LOG2L). tw holds L/2 twiddles:
// exp(-j 2 pi k / L) for a forward FFT, exp(+j 2 pi k / L) for an inverse FFT.
template <int L, int LOG2L>
void fft(cdata x[L], const crom tw[L / 2]) {
    // Bit-reversed reordering.
    cdata tmp[L];
reorder:
    for (int i = 0; i < L; i++) {
#pragma HLS PIPELINE II=1
        int r = 0;
        for (int bit = 0; bit < LOG2L; bit++) {
            r |= ((i >> bit) & 1) << (LOG2L - 1 - bit);
        }
        tmp[r] = x[i];
    }

stages:
    for (int s = 0; s < LOG2L; s++) {
        const int  half   = 1 << s;              // butterfly distance
        const int  stride = L / (2 * half);      // twiddle index step
        const bool scale  = (s % 2) == 0;
    butterflies:
        for (int i = 0; i < L / 2; i++) {
// Two reads and two writes of tmp per butterfly on a dual-port RAM -> II = 2.
// Butterflies of one stage touch disjoint elements, so there is no
// dependence between iterations (stages still run one after another).
#pragma HLS PIPELINE II=2
#pragma HLS DEPENDENCE variable=tmp type=inter false
            const int k  = i & (half - 1);       // position inside the group
            const int ia = ((i >> s) << (s + 1)) + k;
            const int ib = ia + half;
            acc_t tre, tim;
            cmul(tmp[ib], tw[k * stride], tre, tim);
            acc_t sre = tmp[ia].re + tre, sim = tmp[ia].im + tim;
            acc_t dre = tmp[ia].re - tre, dim = tmp[ia].im - tim;
            if (scale) { sre >>= 1; sim >>= 1; dre >>= 1; dim >>= 1; }
            tmp[ia].re = sre;  tmp[ia].im = sim;     // rounds + saturates to data_t
            tmp[ib].re = dre;  tmp[ib].im = dim;
        }
    }

copy_out:
    for (int i = 0; i < L; i++) {
#pragma HLS PIPELINE II=1
        x[i] = tmp[i];
    }
}
