// tb_blocks.cpp - C testbench: every block must match MATLAB bit for bit.
// Usage: tb_blocks <vector_dir>   (e.g. ../generated/W12_R16_LEOKa)
#include <cstdio>
#include <cstring>
#include <string>
#include "blocks.h"

typedef void (*block_fn)(const cdata *, cdata *);

// Runs one block over every frame in <dir>/<name>.txt; returns mismatch count.
static int check_block(const std::string &dir, const char *name, block_fn fn) {
    std::string path = dir + "/" + name + ".txt";
    FILE *f = std::fopen(path.c_str(), "r");
    if (!f) { std::printf("  %-16s cannot open %s\n", name, path.c_str()); return 1; }

    cdata in[N], out[N];
    double ref[N][2];
    int frames = 0, bad = 0;
    while (true) {
        int got = 0;
        for (int n = 0; n < N; n++) {
            double ir, ii, orr, oi;
            if (std::fscanf(f, "%lf %lf %lf %lf", &ir, &ii, &orr, &oi) != 4) break;
            in[n].re = ir;  in[n].im = ii;          // exact: already on the data grid
            ref[n][0] = orr; ref[n][1] = oi;
            got++;
        }
        if (got < N) break;
        fn(in, out);
        for (int n = 0; n < N; n++) {
            if (out[n].re.to_double() != ref[n][0] || out[n].im.to_double() != ref[n][1]) bad++;
        }
        frames++;
    }
    std::fclose(f);
    std::printf("  %-18s %3d frames, %6d samples, %d mismatches\n", name, frames, frames * N, bad);
    return (frames == 0) ? 1 : bad;
}

// dfts_fde has a second input (the equalizer gains): lines r_re r_im w_re w_im out_re out_im.
static int check_fde(const std::string &dir) {
    std::string path = dir + "/dfts_fde.txt";
    FILE *f = std::fopen(path.c_str(), "r");
    if (!f) { std::printf("  %-16s cannot open %s\n", "dfts_fde", path.c_str()); return 1; }

    cdata r[N], out[N];
    cgain w[N];
    double ref[N][2];
    int frames = 0, bad = 0;
    while (true) {
        int got = 0;
        for (int n = 0; n < N; n++) {
            double rr, ri, wr, wi, orr, oi;
            if (std::fscanf(f, "%lf %lf %lf %lf %lf %lf", &rr, &ri, &wr, &wi, &orr, &oi) != 6) break;
            r[n].re = rr;  r[n].im = ri;            // exact: already quantized by MATLAB
            w[n].re = wr;  w[n].im = wi;
            ref[n][0] = orr; ref[n][1] = oi;
            got++;
        }
        if (got < N) break;
        dfts_fde(r, w, out);
        for (int n = 0; n < N; n++) {
            if (out[n].re.to_double() != ref[n][0] || out[n].im.to_double() != ref[n][1]) bad++;
        }
        frames++;
    }
    std::fclose(f);
    std::printf("  %-18s %3d frames, %6d samples, %d mismatches\n", "dfts_fde", frames, frames * N, bad);
    return (frames == 0) ? 1 : bad;
}

int main(int argc, char **argv) {
    if (argc != 2) { std::printf("usage: %s <vector_dir>\n", argv[0]); return 2; }
    std::string dir = argv[1];
    std::printf("WD = %d, WR = %d, vectors: %s\n", WD, WR, dir.c_str());

    int errors = 0;
    errors += check_block(dir, "afdm_mod",          afdm_mod);
    errors += check_block(dir, "afdm_demod",        afdm_demod);
    errors += check_block(dir, "afdm_mod_c2zero",   afdm_mod_c2zero);
    errors += check_block(dir, "afdm_demod_c2zero", afdm_demod_c2zero);
    errors += check_block(dir, "otfs_zak_mod",      otfs_zak_mod);
    errors += check_block(dir, "otfs_zak_demod",    otfs_zak_demod);
    errors += check_block(dir, "otfs_isfft_mod",    otfs_isfft_mod);
    errors += check_block(dir, "otfs_sfft_demod",   otfs_sfft_demod);
    errors += check_block(dir, "otfs_ps_mod",       otfs_ps_mod);
    errors += check_block(dir, "ofdm_mod",          ofdm_mod);
    errors += check_block(dir, "ofdm_demod",        ofdm_demod);
    errors += check_block(dir, "dfts_mod",          dfts_mod);
    errors += check_block(dir, "dfts_demod",        dfts_demod);
    errors += check_fde(dir);

    std::printf(errors == 0 ? "PASS: bit-exact with MATLAB\n" : "FAIL\n");
    return errors == 0 ? 0 : 1;
}
