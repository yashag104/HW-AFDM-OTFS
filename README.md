# HW-AFDM-OTFS

Hardware-complexity-aware comparison of AFDM and OTFS across V2X and LEO mobility regimes:
bit-true fixed-point MATLAB models, then Vitis HLS on one FPGA target (Zynq-7020, PYNQ-Z2),
with resource / timing / power correlated against BER.

## MATLAB (`matlab/`)

Run everything from the `matlab/` folder after `setup_paths`.

| Folder | Contents |
|---|---|
| `config/`   | `sys_params` - frame numerology (N = 256, OTFS 16 x 16, B = 1.92 MHz) and the V2X / LEO-S / LEO-Ka scenarios |
| `channel/`  | TDL profiles (3GPP NTN-TDL-A..D), LEO Doppler and Doppler-rate geometry, random channel draw, time-varying channel (sample-wise and as a matrix) |
| `afdm/`     | chirp ROMs, chirp-periodic prefix, IDAFT modulator, DAFT demodulator |
| `otfs/`     | OTFS via inverse / forward Zak transform, and via ISFFT + Heisenberg / Wigner + SFFT |
| `fixed/`    | `fx` quantizer (bit-exact with HLS `ap_fixed<W,I,AP_RND,AP_SAT>`), bit-true radix-2 FFT |
| `detector/` | effective channel, row truncation to S taps, message-passing detector (shared by both waveforms) |
| `common/`   | QAM tables, unitary FFT wrappers, waveform selector, plot styles |
| `sims/`     | self-checks and studies (below) |

| Script | Output |
|---|---|
| `test_transforms`   | self-checks: unitarity, Zak == ISFFT form, on-grid channel structure, CPP, fixed vs float |
| `doppler_study`     | Doppler and Doppler rate per regime and vs elevation |
| `sweep_sqnr`        | `results/sqnr_sweep.*` - SQNR vs data word length, every Tx / Rx block |
| `ber_vs_snr`        | `results/ber_vs_snr.*` - floating-point BER, all regimes |
| `ber_vs_taps`       | `results/ber_vs_taps.*` - BER vs MP detector taps per row (datapath width) |
| `ber_vs_wordlength` | `results/ber_vs_wordlength.*` - end-to-end BER with fixed-point transforms |

Needs base MATLAB only (no Fixed-Point, Communications or Signal Processing toolboxes).

## HLS (`hls/`)

| File | Contents |
|---|---|
| `src/types.h`   | `ap_fixed` data / ROM types, identical to `fx_config.m` |
| `src/fft.h`     | radix-2 DIT FFT, bit-exact with `fft_fx.m` |
| `src/blocks.cpp`| six top functions: AFDM mod/demod, OTFS Zak mod/demod, OTFS ISFFT/SFFT mod/demod |
| `src/mp.cpp`    | fixed-point MP detector (S taps per row, QPSK, damping, convergence stop) |
| `tb/`           | C testbenches: transforms must match MATLAB bit for bit; MP is checked against the float MATLAB detector |
| `scripts/run_hls.tcl` | C-sim, synthesis and Vivado implementation of one block on `xc7z020clg400-1` @ 100 MHz |

C simulation without Vitis (g++ and AMD's open-source headers):

```sh
git clone https://github.com/Xilinx/HLS_arbitrary_Precision_Types hls/third_party/ap_types
# in MATLAB (matlab/): setup_paths; export_hls_vectors(12, 16, 'LEO-Ka', 20); export_mp_frames('LEO-Ka', 'AFDM', 12, 16, 12, 200)
cd hls && make check WD=12 WR=16 SCEN=LEOKa && make mp-check MP_S=16 FRAMES=generated/mp/LEOKa_AFDM_S16_12dB.txt
```

Synthesis (needs Vitis HLS 2024.2+): `TOP=afdm_mod WD=12 WR=16 SCEN=LEOKa vitis-run --mode hls --tcl scripts/run_hls.tcl`

**Open items:** the V2X tap profile is a placeholder (`tdl_profile.m`); the LEO delay spread
(300 ns) and Doppler pre-compensation interval (20 ms) are assumptions to be set from TR 38.811.
