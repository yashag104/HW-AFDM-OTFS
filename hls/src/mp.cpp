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
static const int    EPS_TENTHS = 2;                   // eps = 0.2: stop if count drops by eps * (data symbols)

// exp(d) for d <= 0, from the table at step 1/8 (index = floor(-8 d)).
static prob_t exp_lut(lsum_t d) {
    lsum_t scaled = -d * 8;
    int i = scaled.to_int();
    return (i >= EXP_SZ) ? prob_t(0) : EXP_TABLE[i];
}

void mp_detect(const cdata y[N], const idx_t col[N][S], const ctap h[N][S], var_t n0,
               const var_t drop[N], const ap_uint<1> is_data[N],
               sym_t xhat[N], ap_uint<8> &iters) {
    static prob_t P[N][S][Q];     // variable -> observation messages, per edge
    static ll_t   LL[N][S][Q];    // observation -> variable log-likelihoods, per edge
    static lsum_t Lt[N][Q];       // per-symbol sums over the column
    // Architecture: one factor-graph edge (a, s) per clock, its Q symbol values
    // in parallel. Without these directives HLS unrolled the S x Q loops (all
    // 220 DSPs, 12.8 ns > 10 ns clock), results/hw/mp_S16_small.log.
#pragma HLS ARRAY_PARTITION variable=P  type=complete dim=3
#pragma HLS ARRAY_PARTITION variable=LL type=complete dim=3
#pragma HLS ARRAY_PARTITION variable=Lt type=complete dim=2
#pragma HLS BIND_STORAGE variable=Lt type=ram_t2p   // read + write every cycle in scatter (was II=4)
    static mean_t M1RE[NE], M1IM[NE];   // per-edge symbol mean (pass 1 -> pass 2)
    static var_t  VX[NE];               // per-edge symbol variance
    static mean_t MURE[N], MUIM[N];     // per-row interference mean
    static var_t  VAR[N];               // per-row noise + interference variance

init:
    for (int a = 0; a < N; a++)
        for (int s = 0; s < S; s++)
            for (int q = 0; q < Q; q++) P[a][s][q] = prob_t(1.0 / Q);

    // Convergence is counted over the unknown (data) symbols only.
    int ndata = 0;
count_data:
    for (int b = 0; b < N; b++) ndata += is_data[b].to_int();
    const int eps_cnt = (EPS_TENTHS * ndata) / 10;

    int best = -1;
    int it   = 0;
iterations:
    for (it = 1; it <= ITER; it++) {
        // ---------- observation nodes ----------
        // Pass 1, every edge e = (a, s) in one pipeline: symbol mean and
        // variance of the edge, and the row sums mu, var (same order of
        // additions as the row loop it replaces, so results are unchanged).
        mean_t mure = 0, muim = 0;
        var_t  var  = 0;
    obs_mean:
        for (int e = 0; e < NE; e++) {
#pragma HLS PIPELINE II=1
            const int a = e / S, s = e % S;
            if (s == 0) { mure = 0; muim = 0; var = n0 + drop[a]; }
            mean_t er = 0, ei = 0;
            var_t  e2 = 0;
            for (int q = 0; q < Q; q++) {
                er += P[a][s][q] * CONST[q].re;
                ei += P[a][s][q] * CONST[q].im;
                e2 += P[a][s][q] * CONST_POW[q];
            }
            mean_t mag = er * er + ei * ei;
            const var_t v = (e2 > mag) ? var_t(e2 - mag) : var_t(0);
            VX[e] = v;  M1RE[e] = er;  M1IM[e] = ei;
            mure += h[a][s].re * er - h[a][s].im * ei;
            muim += h[a][s].re * ei + h[a][s].im * er;
            var  += (h[a][s].re * h[a][s].re + h[a][s].im * h[a][s].im) * v;
            if (s == S - 1) { MURE[a] = mure; MUIM[a] = muim; VAR[a] = var; }
        }
        // Pass 2: extrinsic interference of each edge and its log-likelihoods.
    obs_ll:
        for (int e = 0; e < NE; e++) {
#pragma HLS PIPELINE II=1
            const int a = e / S, s = e % S;
            const var_t n0r = n0 + drop[a];   // noise + interference of the dropped taps
            const tap_t hr = h[a][s].re, hi = h[a][s].im;
            mean_t ure = MURE[a] - (hr * M1RE[e] - hi * M1IM[e]);
            mean_t uim = MUIM[a] - (hr * M1IM[e] + hi * M1RE[e]);
            var_t  ve  = VAR[a] - (hr * hr + hi * hi) * VX[e];
            if (ve < n0r) ve = n0r;
            inv_t  iv  = inv_t(1) / ve;
            for (int q = 0; q < Q; q++) {
                mean_t dr = y[a].re - ure - (hr * CONST[q].re - hi * CONST[q].im);
                mean_t di = y[a].im - uim - (hr * CONST[q].im + hi * CONST[q].re);
                LL[a][s][q] = -((dr * dr + di * di) * iv);
            }
        }

        // ---------- variable nodes: sum log-likelihoods per column ----------
    clear_sum:
        for (int b = 0; b < N; b++) {
#pragma HLS PIPELINE II=1
            for (int q = 0; q < Q; q++) Lt[b][q] = 0;
        }
    scatter:
        for (int e = 0; e < NE; e++) {
#pragma HLS PIPELINE
            const int a = e / S, s = e % S;
            const idx_t c = col[a][s];
            for (int q = 0; q < Q; q++) {
                const lsum_t t = Lt[c][q] + LL[a][s][q];   // saturated sum, one store per bank
                Lt[c][q] = t;
            }
        }

        // ---------- extrinsic messages with damping ----------
    var_msg:
        for (int e = 0; e < NE; e++) {
#pragma HLS PIPELINE II=1
            const int a = e / S, s = e % S;
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

        // ---------- decisions and convergence indicator ----------
        int count = 0;
        sym_t dec[N];
    decide:
        for (int b = 0; b < N; b++) {
#pragma HLS PIPELINE II=1
            lsum_t mx = Lt[b][0];
            sym_t  arg = 0;
            for (int q = 1; q < Q; q++) if (Lt[b][q] > mx) { mx = Lt[b][q]; arg = q; }
            esum_t sum = 0;
            for (int q = 0; q < Q; q++) sum += exp_lut(Lt[b][q] - mx);
            if (is_data[b] && sum <= CONV_SUM) count++;   // max probability = 1 / sum >= 1 - gamma
            dec[b] = arg;
        }
        if (count > best) {
            best = count;
        keep:
            for (int b = 0; b < N; b++) xhat[b] = dec[b];
        }
        if (count == ndata || count < best - eps_cnt) break;
    }
    iters = (it > ITER) ? ITER : it;
}
