// tb_mp.cpp - testbench for the fixed-point MP detector.
// Runs frames exported by matlab/sims/export_mp_frames.m and compares the
// fixed-point decisions with the transmitted symbols and with the
// floating-point MATLAB detector on the same frames.
// Usage: tb_mp <frames.txt> [max_ber_ratio]
//   passes if BER_fixed <= max_ber_ratio * BER_float + 1e-4 (default ratio 1.5)
#include <cstdio>
#include <cstdlib>
#include "mp.h"

static int bit_errors(int a, int b) { int d = a ^ b; return (d & 1) + ((d >> 1) & 1); }

int main(int argc, char **argv) {
    if (argc < 2) { std::printf("usage: %s <frames.txt> [max_ber_ratio]\n", argv[0]); return 2; }
    const double ratio = (argc > 2) ? std::atof(argv[2]) : 1.5;
    FILE *f = std::fopen(argv[1], "r");
    if (!f) { std::printf("cannot open %s\n", argv[1]); return 2; }

    static cdata y[N];
    static idx_t col[N][S];
    static ctap  h[N][S];
    static int   tx[N], xf[N];
    static var_t drop[N];
    static ap_uint<1> isd[N];
    sym_t xhat[N];
    ap_uint<8> iters;

    long errFix = 0, errFlt = 0, agree = 0, bits = 0, itSum = 0, dataSyms = 0;
    int frames = 0;
    double n0;
    while (std::fscanf(f, "%lf", &n0) == 1) {
        bool ok = true;
        for (int a = 0; a < N && ok; a++) {
            double yr, yi, dr;
            int d;
            ok = std::fscanf(f, "%lf %lf %d %d %lf %d", &yr, &yi, &tx[a], &xf[a], &dr, &d) == 6;
            y[a].re = yr;  y[a].im = yi;
            drop[a] = dr;  isd[a] = d;
            for (int s = 0; s < S && ok; s++) {
                int c; double hr, hi;
                ok = std::fscanf(f, "%d %lf %lf", &c, &hr, &hi) == 3;
                col[a][s] = c;  h[a][s].re = hr;  h[a][s].im = hi;
            }
        }
        if (!ok) { std::printf("file ended inside a frame (is MP_S = %d right?)\n", S); return 2; }

        mp_detect(y, col, h, var_t(n0), drop, isd, xhat, iters);

        int nd = 0;
        for (int a = 0; a < N; a++) {
            if (!isd[a]) continue;                   // known pilot / guard position
            errFix += bit_errors(tx[a], xhat[a].to_int());
            errFlt += bit_errors(tx[a], xf[a]);
            agree  += (xhat[a].to_int() == xf[a]);
            nd++;
        }
        bits  += 2 * nd;
        dataSyms += nd;
        itSum += iters.to_int();
        frames++;
    }
    std::fclose(f);
    if (frames == 0) { std::printf("no frames read\n"); return 2; }

    const double berFix = double(errFix) / bits, berFlt = double(errFlt) / bits;
    std::printf("S = %d, frames = %d, bits = %ld\n", S, frames, bits);
    std::printf("  BER fixed-point MP : %.3e (%ld errors)\n", berFix, errFix);
    std::printf("  BER float MP (ref) : %.3e (%ld errors)\n", berFlt, errFlt);
    std::printf("  decision agreement : %.4f\n", double(agree) / dataSyms);
    std::printf("  mean iterations    : %.2f (max %d)\n", double(itSum) / frames, ITER);
    const bool pass = berFix <= ratio * berFlt + 1e-4;
    std::printf("RESULT S=%d frames=%d errFix=%ld errFlt=%ld bits=%ld agree=%.5f iters=%.2f\n",
                S, frames, errFix, errFlt, bits, double(agree) / dataSyms, double(itSum) / frames);
    std::printf(pass ? "PASS\n" : "FAIL: fixed-point loss too large\n");
    return pass ? 0 : 1;
}
