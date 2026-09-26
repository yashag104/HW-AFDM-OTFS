// blocks.h - the six synthesizable top functions (one per transform block).
// Every block maps an N-sample frame to an N-sample frame. OTFS frames are the
// M x K delay-Doppler grid stored column-major: sample index = l + M * k.
#pragma once
#include "types.h"

void afdm_mod(const cdata x[N], cdata s[N]);          // IDAFT: pre-chirp, IFFT_N, post-chirp
void afdm_demod(const cdata r[N], cdata y[N]);        // DAFT : chirp, FFT_N, chirp
void otfs_zak_mod(const cdata x[N], cdata s[N]);      // inverse Zak: IFFT_K per delay row
void otfs_zak_demod(const cdata r[N], cdata y[N]);    // Zak        : FFT_K per delay row
void otfs_isfft_mod(const cdata x[N], cdata s[N]);    // ISFFT + Heisenberg (3 FFT stages)
void otfs_sfft_demod(const cdata r[N], cdata y[N]);   // Wigner + SFFT      (3 FFT stages)
