// blocks.h - the synthesizable top functions (one per transform block).
// Every block maps an N-sample frame to an N-sample frame. OTFS frames are the
// M x K delay-Doppler grid stored column-major: sample index = l + M * k.
#pragma once
#include "types.h"

void afdm_mod(const cdata x[N], cdata s[N]);          // IDAFT: pre-chirp, IFFT_N, post-chirp
void afdm_demod(const cdata r[N], cdata y[N]);        // DAFT : chirp, FFT_N, chirp
void afdm_mod_c2zero(const cdata x[N], cdata s[N]);   // IDAFT with c2 = 0 (no pre-chirp pass)
void afdm_demod_c2zero(const cdata r[N], cdata y[N]); // DAFT  with c2 = 0 (no post-chirp pass)
void otfs_zak_mod(const cdata x[N], cdata s[N]);      // inverse Zak: IFFT_K per delay row
void otfs_zak_demod(const cdata r[N], cdata y[N]);    // Zak        : FFT_K per delay row
void otfs_isfft_mod(const cdata x[N], cdata s[N]);    // ISFFT + Heisenberg (3 FFT passes)
void otfs_sfft_demod(const cdata r[N], cdata y[N]);   // Wigner + SFFT      (3 FFT passes)
void otfs_ps_mod(const cdata x[N], cdata s[N]);       // ISFFT + TF window + Heisenberg
void ofdm_mod(const cdata x[N], cdata s[N]);          // OFDM baseline: IFFT_N
void ofdm_demod(const cdata r[N], cdata y[N]);        // OFDM baseline: FFT_N
void dfts_mod(const cdata x[N], cdata s[N]);          // DFT-s-OFDM: DFT_N spread, IFFT_N
void dfts_demod(const cdata r[N], cdata y[N]);        // DFT-s-OFDM: FFT_N, IDFT_N despread
void dfts_fde(const cdata r[N], const cgain w[N], cdata x[N]); // DFT-s-OFDM Rx: FFT_N, one-tap gains, IDFT_N
