// blocks.cpp - AFDM and OTFS transform blocks, bit-exact with the MATLAB models
// (matlab/afdm/afdm_mod.m, afdm_demod.m, matlab/otfs/*.m).
#include "blocks.h"
#include "fft.h"
#include "rom_tables.h"

// y = round(x * conj(c))  or  round(x * c)
static inline cdata chirp_mul(const cdata &x, const crom &c, bool conjugate) {
    acc_t re, im;
    if (conjugate) {
        re = acc_t(x.re * c.re) + acc_t(x.im * c.im);
        im = acc_t(x.im * c.re) - acc_t(x.re * c.im);
    } else {
        re = acc_t(x.re * c.re) - acc_t(x.im * c.im);
        im = acc_t(x.re * c.im) + acc_t(x.im * c.re);
    }
    cdata y;
    y.re = re;
    y.im = im;
    return y;
}

// ---------------------------------------------------------------- AFDM

void afdm_mod(const cdata x[N], cdata s[N]) {
    cdata buf[N];
pre_chirp:
    for (int n = 0; n < N; n++) buf[n] = chirp_mul(x[n], CHIRP2[n], true);
    fft<N, 8>(buf, TW256_INV);
post_chirp:
    for (int n = 0; n < N; n++) s[n] = chirp_mul(buf[n], CHIRP1[n], true);
}

void afdm_demod(const cdata r[N], cdata y[N]) {
    cdata buf[N];
pre_chirp:
    for (int n = 0; n < N; n++) buf[n] = chirp_mul(r[n], CHIRP1[n], false);
    fft<N, 8>(buf, TW256_FWD);
post_chirp:
    for (int n = 0; n < N; n++) y[n] = chirp_mul(buf[n], CHIRP2[n], false);
}

// AFDM with c2 = 0: the c2 chirp is exactly 1, so its pass is dropped
// (bit-identical to afdm_mod / afdm_demod run with c2 = 0).
void afdm_mod_c2zero(const cdata x[N], cdata s[N]) {
    cdata buf[N];
    for (int n = 0; n < N; n++) buf[n] = x[n];
    fft<N, 8>(buf, TW256_INV);
post_chirp:
    for (int n = 0; n < N; n++) s[n] = chirp_mul(buf[n], CHIRP1[n], true);
}

void afdm_demod_c2zero(const cdata r[N], cdata y[N]) {
    cdata buf[N];
pre_chirp:
    for (int n = 0; n < N; n++) buf[n] = chirp_mul(r[n], CHIRP1[n], false);
    fft<N, 8>(buf, TW256_FWD);
    for (int n = 0; n < N; n++) y[n] = buf[n];
}

// ---------------------------------------------------------------- OFDM baseline

void ofdm_mod(const cdata x[N], cdata s[N]) {
    cdata buf[N];
    for (int n = 0; n < N; n++) buf[n] = x[n];
    fft<N, 8>(buf, TW256_INV);
    for (int n = 0; n < N; n++) s[n] = buf[n];
}

void ofdm_demod(const cdata r[N], cdata y[N]) {
    cdata buf[N];
    for (int n = 0; n < N; n++) buf[n] = r[n];
    fft<N, 8>(buf, TW256_FWD);
    for (int n = 0; n < N; n++) y[n] = buf[n];
}

// ------------------------------------------------------ DFT-s-OFDM (NR uplink)
// Full allocation (M = N): spreading DFT then OFDM IFFT, and the reverse.
// Both transforms are built even though they cancel in floating point: a
// real transmitter needs them for partial allocations (matlab/ofdm/dfts_*.m).

void dfts_mod(const cdata x[N], cdata s[N]) {
    cdata buf[N];
    for (int n = 0; n < N; n++) buf[n] = x[n];
    fft<N, 8>(buf, TW256_FWD);                 // spreading DFT
    fft<N, 8>(buf, TW256_INV);                 // OFDM IFFT
    for (int n = 0; n < N; n++) s[n] = buf[n];
}

void dfts_demod(const cdata r[N], cdata y[N]) {
    cdata buf[N];
    for (int n = 0; n < N; n++) buf[n] = r[n];
    fft<N, 8>(buf, TW256_FWD);                 // OFDM FFT
    fft<N, 8>(buf, TW256_INV);                 // despreading IDFT
    for (int n = 0; n < N; n++) y[n] = buf[n];
}

// ---------------------------------------------------------------- OTFS helpers

// K-point FFT along every delay row l: elements l + M*k, k = 0..K-1.
static void rows_fft(cdata g[N], const crom tw[K / 2]) {
rows:
    for (int l = 0; l < M; l++) {
        cdata row[K];
        for (int k = 0; k < K; k++) row[k] = g[l + M * k];
        fft<K, 4>(row, tw);
        for (int k = 0; k < K; k++) g[l + M * k] = row[k];
    }
}

// M-point FFT along every column k: elements l + M*k, l = 0..M-1.
static void cols_fft(cdata g[N], const crom tw[M / 2]) {
cols:
    for (int k = 0; k < K; k++) {
        cdata col[M];
        for (int l = 0; l < M; l++) col[l] = g[l + M * k];
        fft<M, 4>(col, tw);
        for (int l = 0; l < M; l++) g[l + M * k] = col[l];
    }
}

// ---------------------------------------------------------------- OTFS, Zak form

void otfs_zak_mod(const cdata x[N], cdata s[N]) {
    cdata g[N];
    for (int i = 0; i < N; i++) g[i] = x[i];
    rows_fft(g, TW16_INV);                 // S = X * F_K^H
    for (int i = 0; i < N; i++) s[i] = g[i];
}

void otfs_zak_demod(const cdata r[N], cdata y[N]) {
    cdata g[N];
    for (int i = 0; i < N; i++) g[i] = r[i];
    rows_fft(g, TW16_FWD);                 // Y = R * F_K
    for (int i = 0; i < N; i++) y[i] = g[i];
}

// ---------------------------------------------------------------- OTFS, two-step form

void otfs_isfft_mod(const cdata x[N], cdata s[N]) {
    cdata g[N];
    for (int i = 0; i < N; i++) g[i] = x[i];
    cols_fft(g, TW16_FWD);                 // ISFFT: F_M * X
    rows_fft(g, TW16_INV);                 //        ... * F_K^H
    cols_fft(g, TW16_INV);                 // Heisenberg: F_M^H * X_TF
    for (int i = 0; i < N; i++) s[i] = g[i];
}

// Pulse-shaped OTFS: the TF window sits between ISFFT and Heisenberg, so the
// three passes cannot collapse into the Zak form. Receiver: otfs_sfft_demod.
void otfs_ps_mod(const cdata x[N], cdata s[N]) {
    cdata g[N];
    for (int i = 0; i < N; i++) g[i] = x[i];
    cols_fft(g, TW16_FWD);                 // ISFFT: F_M * X
    rows_fft(g, TW16_INV);                 //        ... * F_K^H
window:
    for (int i = 0; i < N; i++) {          // real window, one sample at a time
        acc_t re = g[i].re * WINDOW[i];
        acc_t im = g[i].im * WINDOW[i];
        g[i].re = re;  g[i].im = im;
    }
    cols_fft(g, TW16_INV);                 // Heisenberg: F_M^H * X_TF
    for (int i = 0; i < N; i++) s[i] = g[i];
}

void otfs_sfft_demod(const cdata r[N], cdata y[N]) {
    cdata g[N];
    for (int i = 0; i < N; i++) g[i] = r[i];
    cols_fft(g, TW16_FWD);                 // Wigner: F_M * R
    cols_fft(g, TW16_INV);                 // SFFT:   F_M^H * Y_TF
    rows_fft(g, TW16_FWD);                 //         ... * F_K
    for (int i = 0; i < N; i++) y[i] = g[i];
}
