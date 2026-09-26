// mp.h - fixed-point message-passing detector (same datapath for AFDM and OTFS).
// Floating-point reference: matlab/detector/mp_detector.m
#pragma once
#include <ap_fixed.h>
#include <ap_int.h>
#include "types.h"

#ifndef MP_S
#define MP_S 16           // channel taps per row (datapath width)
#endif
#ifndef MP_ITER
#define MP_ITER 10        // maximum iterations (worst-case latency), = p.mp.iter
#endif

const int S      = MP_S;
const int Q      = 4;     // QPSK
const int ITER   = MP_ITER;
const int NE     = N * S; // edges of the factor graph
const int EXP_SZ = 128;   // exp LUT entries, step 1/8 -> covers exp(0) .. exp(-15.9)

typedef ap_fixed<12, 2, AP_RND, AP_SAT>  tap_t;   // channel taps and constellation
typedef ap_fixed<18, 4, AP_RND, AP_SAT>  mean_t;  // interference mean
typedef ap_ufixed<18, 4, AP_RND, AP_SAT> var_t;   // interference variance, N0
typedef ap_ufixed<20, 9, AP_RND, AP_SAT> inv_t;   // 1 / variance
typedef ap_fixed<16, 9, AP_RND, AP_SAT>  ll_t;    // log-likelihood per edge
typedef ap_fixed<20, 13, AP_RND, AP_SAT> lsum_t;  // sum of log-likelihoods per symbol
typedef ap_ufixed<12, 1, AP_RND, AP_SAT> prob_t;  // message probability
typedef ap_ufixed<16, 4, AP_RND, AP_SAT> esum_t;  // sum of exp values (1 .. Q)
typedef ap_uint<8>                       idx_t;   // column index 0 .. N-1
typedef ap_uint<2>                       sym_t;   // QPSK symbol index

struct ctap { tap_t re, im; };

// Detects one frame.
//   y      : N received samples (detection domain)
//   col    : N x S column index of each kept tap
//   h      : N x S tap values
//   n0     : noise variance
//   xhat   : N detected symbol indices (decision of the best iteration)
//   iters  : iterations run (<= ITER)
void mp_detect(const cdata y[N], const idx_t col[N][S], const ctap h[N][S], var_t n0,
               sym_t xhat[N], ap_uint<8> &iters);
