// tb_board.cpp - C testbench of the board wrapper afdm_mod_top: packs the
// MATLAB input vectors into 32-bit words, runs the top, unpacks, and checks
// every output bit for bit.
// Usage: tb_board <vector_dir>   (e.g. .../generated/W12_R16_LEOKa)
#include <cstdio>
#include <string>
#include <ap_int.h>
#include "types.h"

typedef ap_uint<32> word_t;
void afdm_mod_top(const word_t in[N], word_t out[N]);

static word_t to_word(double re, double im) {
    data_t r = re, i = im;                       // exact: vectors are on the data grid
    ap_int<16> r16, i16;
    ap_int<WD> rr, ii;
    rr.range(WD - 1, 0) = r.range(WD - 1, 0);
    ii.range(WD - 1, 0) = i.range(WD - 1, 0);
    r16 = rr;  i16 = ii;
    word_t w;
    w.range(15, 0) = r16.range(15, 0);
    w.range(31, 16) = i16.range(15, 0);
    return w;
}

static double half_to_double(word_t w, int lo) {
    ap_int<16> v = w.range(lo + 15, lo);
    data_t d;
    d.range(WD - 1, 0) = v.range(WD - 1, 0);
    return d.to_double();
}

int main(int argc, char **argv) {
    if (argc != 2) { std::printf("usage: %s <vector_dir>\n", argv[0]); return 2; }
    std::string path = std::string(argv[1]) + "/afdm_mod.txt";
    FILE *f = std::fopen(path.c_str(), "r");
    if (!f) { std::printf("cannot open %s\n", path.c_str()); return 2; }

    static word_t in[N], out[N];
    static double ref[N][2];
    int frames = 0, bad = 0;
    while (true) {
        int got = 0;
        for (int n = 0; n < N; n++) {
            double ir, ii, orr, oi;
            if (std::fscanf(f, "%lf %lf %lf %lf", &ir, &ii, &orr, &oi) != 4) break;
            in[n] = to_word(ir, ii);
            ref[n][0] = orr;  ref[n][1] = oi;
            got++;
        }
        if (got < N) break;
        afdm_mod_top(in, out);
        for (int n = 0; n < N; n++) {
            if (half_to_double(out[n], 0) != ref[n][0] || half_to_double(out[n], 16) != ref[n][1]) bad++;
        }
        frames++;
    }
    std::fclose(f);
    std::printf("afdm_mod_top: %d frames, %d samples, %d mismatches\n", frames, frames * N, bad);
    std::printf((frames > 0 && bad == 0) ? "PASS: bit-exact with MATLAB\n" : "FAIL\n");
    return (frames > 0 && bad == 0) ? 0 : 1;
}
