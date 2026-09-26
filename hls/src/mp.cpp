// mp.cpp - fixed-point message-passing detector (Raviteja et al., IEEE TWC 2018),
// with damping and convergence-based stopping. See mp.h for the interface.
#include "mp.h"
#include "exp_lut.h"

// QPSK, identical to matlab/common/qam_table.m (Q = 4):
// index i -> (bit1 ? +1 : -1) + j (bit0 ? +1 : -1), divided by sqrt(2)
static const ctap CONST[Q] = {{-0.70710678, -0.70710678}, {-0.70710678, 0.70710678},
                              { 0.70710678, -0.70710678}, { 0.70710678, 0.70710678}};
static const tap_t CONST_POW[Q] = {1.0, 1.0, 1.0, 1.0};   // |c|^2 of the unit-energy constellation

// Settings shared with matlab/config/sys_params.m (p.mp)
static const prob_t DAMP     = 0.7;                   // damping
static const esum_t CONV_SUM = 1.0 / (1.0 - 0.01);    // converged if sum of exp <= 1/(1-gamma)
static const int    EPS_CNT  = (int)(0.2 * N);        // stop if count drops by eps*N

// exp(d) for d <= 0, from the table at step 1/8 (index = floor(-8 d)).
static prob_t exp_lut(lsum_t d) {
    lsum_t scaled = -d * 8;
    int i = scaled.to_int();
    return (i >= EXP_SZ) ? prob_t(0) : EXP_TABLE[i];
}

void mp_detect(const cdata y[N], const idx_t col[N][S], const ctap h[N][S], var_t n0,
               sym_t xhat[N], ap_uint<8> &iters) {
    static prob_t P[N][S][Q];     // variable -> observation messages, per edge
    static ll_t   LL[N][S][Q];    // observation -> variable log-likelihoods, per edge
    static lsum_t Lt[N][Q];       // per-symbol sums over the column

init:
    for (int a = 0; a < N; a++)
        for (int s = 0; s < S; s++)
            for (int q = 0; q < Q; q++) P[a][s][q] = prob_t(1.0 / Q);

    int best = -1;
    int it   = 0;
iterations:
    for (it = 1; it <= ITER; it++) {
        // ---------- observation nodes ----------
    obs:
        for (int a = 0; a < N; a++) {
            mean_t m1re[S], m1im[S];
            var_t  vx[S];
            mean_t mure = 0, muim = 0;
            var_t  var  = n0;
            for (int s = 0; s < S; s++) {
                mean_t er = 0, ei = 0;
                var_t  e2 = 0;
                for (int q = 0; q < Q; q++) {
                    er += P[a][s][q] * CONST[q].re;
                    ei += P[a][s][q] * CONST[q].im;
                    e2 += P[a][s][q] * CONST_POW[q];
                }
                mean_t mag = er * er + ei * ei;
                vx[s]   = (e2 > mag) ? var_t(e2 - mag) : var_t(0);
                m1re[s] = er;  m1im[s] = ei;
                mure += h[a][s].re * er - h[a][s].im * ei;
                muim += h[a][s].re * ei + h[a][s].im * er;
                var  += (h[a][s].re * h[a][s].re + h[a][s].im * h[a][s].im) * vx[s];
            }
            for (int s = 0; s < S; s++) {
                const tap_t hr = h[a][s].re, hi = h[a][s].im;
                mean_t ure = mure - (hr * m1re[s] - hi * m1im[s]);
                mean_t uim = muim - (hr * m1im[s] + hi * m1re[s]);
                var_t  ve  = var - (hr * hr + hi * hi) * vx[s];
                if (ve < n0) ve = n0;
                inv_t  iv  = inv_t(1) / ve;
                for (int q = 0; q < Q; q++) {
                    mean_t dr = y[a].re - ure - (hr * CONST[q].re - hi * CONST[q].im);
                    mean_t di = y[a].im - uim - (hr * CONST[q].im + hi * CONST[q].re);
                    LL[a][s][q] = -((dr * dr + di * di) * iv);
                }
            }
        }

        // ---------- variable nodes: sum log-likelihoods per column ----------
    clear_sum:
        for (int b = 0; b < N; b++)
            for (int q = 0; q < Q; q++) Lt[b][q] = 0;
    scatter:
        for (int a = 0; a < N; a++)
            for (int s = 0; s < S; s++)
                for (int q = 0; q < Q; q++) Lt[col[a][s]][q] += LL[a][s][q];

        // ---------- extrinsic messages with damping ----------
    var_msg:
        for (int a = 0; a < N; a++) {
            for (int s = 0; s < S; s++) {
                lsum_t ext[Q];
                for (int q = 0; q < Q; q++) ext[q] = Lt[col[a][s]][q] - LL[a][s][q];
                lsum_t mx = ext[0];
                for (int q = 1; q < Q; q++) if (ext[q] > mx) mx = ext[q];
                prob_t ex[Q];
                esum_t sum = 0;
                for (int q = 0; q < Q; q++) { ex[q] = exp_lut(ext[q] - mx); sum += ex[q]; }
                for (int q = 0; q < Q; q++) {
                    prob_t pn = ex[q] / sum;
                    P[a][s][q] = DAMP * pn + (prob_t(1) - DAMP) * P[a][s][q];
                }
            }
        }

        // ---------- decisions and convergence indicator ----------
        int count = 0;
        sym_t dec[N];
    decide:
        for (int b = 0; b < N; b++) {
            lsum_t mx = Lt[b][0];
            sym_t  arg = 0;
            for (int q = 1; q < Q; q++) if (Lt[b][q] > mx) { mx = Lt[b][q]; arg = q; }
            esum_t sum = 0;
            for (int q = 0; q < Q; q++) sum += exp_lut(Lt[b][q] - mx);
            if (sum <= CONV_SUM) count++;             // max probability = 1 / sum >= 1 - gamma
            dec[b] = arg;
        }
        if (count > best) {
            best = count;
        keep:
            for (int b = 0; b < N; b++) xhat[b] = dec[b];
        }
        if (count == N || count < best - EPS_CNT) break;
    }
    iters = (it > ITER) ? ITER : it;
}
