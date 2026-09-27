# HW-AFDM-OTFS

Hardware-complexity-aware comparison of AFDM and OTFS across V2X and LEO mobility regimes:
bit-true fixed-point MATLAB models, then Vitis HLS on one FPGA target (Zynq-7020, PYNQ-Z2),
with resource / timing / power correlated against BER. OFDM is the cost baseline.

## MATLAB (`matlab/`)

Run everything from the `matlab/` folder after `setup_paths`. Base MATLAB only
(no Fixed-Point, Communications or Signal Processing toolboxes).

| Folder | Contents |
|---|---|
| `config/`     | `sys_params` - frame numerology (N = 256, OTFS 16 x 16, B = 1.92 MHz), V2X / LEO-S / LEO-Ka scenarios, name-value overrides for sweeps |
| `channel/`    | 3GPP NTN-TDL-A..D profiles, LEO Doppler and Doppler-rate geometry, random channel with fractional delays (raised-cosine pulse), time-varying channel (sample-wise and as a matrix) |
| `afdm/`       | chirp ROMs, chirp-periodic prefix, IDAFT modulator, DAFT demodulator (c2 = 0 variant via `sys_params`) |
| `otfs/`       | OTFS via inverse / forward Zak transform, via ISFFT + Heisenberg / Wigner + SFFT, and pulse-shaped OTFS (transmit TF window) |
| `ofdm/`       | OFDM baseline (one IFFT / FFT) |
| `fixed/`      | `fx` quantizer (bit-exact with HLS `ap_fixed<W,I,AP_RND,AP_SAT>`), bit-true radix-2 FFT |
| `detector/`   | effective channel, S-largest and per-path tap selection, MP detector, LMMSE reference |
| `estimation/` | pilot / guard layout per waveform, delay-Doppler dictionary, OMP channel estimator |
| `common/`     | QAM tables, unitary FFT wrappers, waveform selector, plot styles |
| `sims/`       | BER engine (`ber_curve`, with 95 % confidence intervals), self-checks and studies (below) |

| Script | Output |
|---|---|
| `test_transforms`       | self-checks: unitarity, Zak == ISFFT form, on-grid structure, CPP, fractional-delay channel, fixed vs float, estimator, detectors |
| `doppler_study`         | Doppler and Doppler rate per regime and vs elevation |
| `sweep_sqnr`            | `results/sqnr_sweep.*` - SQNR vs data word length, every Tx / Rx block |
| `study_fairness(scen)`  | `results/fairness_*.mat` - every waveform with MP (S largest), MP (per path) and LMMSE |
| `study_taps(scen)`      | `results/taps_*.mat` - BER vs detector width for both tap-selection rules |
| `study_estimation(scen)`| `results/estimation_*.mat` - pilot-based estimation vs genie CSI, pilot overhead |
| `study_wordlength(scen)`| `results/wordlength_*.mat` - fixed-point BER with receive gain control, saturation counts |
| `study_small(which)`    | AFDM xi / c2, Doppler-drift, NTN profile x delay spread, bandwidth, 16-QAM (`summarize_small` prints tables) |
| `mp_config_study(scen)` | MP iterations, damping and stopping thresholds at 12 and 18 dB |
| `study_papr`            | `results/papr.*` - PAPR CCDF |
| `plot_studies(which)`   | figures for the studies above |

## HLS (`hls/`)

| File | Contents |
|---|---|
| `src/types.h`    | `ap_fixed` data / ROM / window types, identical to `fx_config.m` |
| `src/fft.h`      | radix-2 DIT FFT, bit-exact with `fft_fx.m`; two architectures (`ARCH=0` in place II = 2, `ARCH=1` ping-pong II = 1) |
| `src/blocks.cpp` | AFDM mod/demod (and c2 = 0 variants), OTFS Zak, ISFFT/SFFT and pulse-shaped mod, OFDM mod/demod |
| `src/mp.cpp`     | fixed-point MP detector (S taps per row, QPSK, damping, convergence stop; word lengths set by `MP_W*` macros) |
| `tb/`            | C testbenches: transforms must match MATLAB bit for bit; MP is checked against the float MATLAB detector |
| `scripts/run_hls.tcl` | C-sim, synthesis and Vivado implementation of one block on `xc7z020clg400-1` @ 100 MHz |

C simulation without Vitis (g++ and AMD's open-source headers, pinned commit):

```sh
git clone https://github.com/Xilinx/HLS_arbitrary_Precision_Types hls/third_party/ap_types
git -C hls/third_party/ap_types checkout 200a9aecaadf471592558540dc5a88256cbf880f
# in MATLAB (matlab/): setup_paths; export_hls_vectors(12, 16, 'LEO-Ka', 20); export_mp_frames('LEO-Ka', 'AFDM', 12, 16, 12, 200)
cd hls && make check WD=12 WR=16 SCEN=LEOKa && make mp-check MP_S=16 FRAMES=generated/mp/LEOKa_AFDM_S16_12dB.txt
```

Synthesis (needs Vitis HLS 2024.2+): `TOP=afdm_mod WD=12 WR=16 SCEN=LEOKa vitis-run --mode hls --tcl scripts/run_hls.tcl`

## Open items

- V2X tap profile is a placeholder (`tdl_profile.m`); V2X results are not for publication until it is replaced.
- LEO delay spread (300 ns) and Doppler pre-compensation interval (20 ms) are assumptions; both are swept.
- OFDM is evaluated with genie CSI only (one symbol per frame cannot resolve this Doppler from comb pilots).
- Not yet run: synthesis, place-and-route, co-simulation power, on-board tests (need Vitis HLS / Vivado).
- The receiver's channel-tap generator (estimated paths -> S taps per row) is not in the hardware comparison yet.

`docs/study_overview.html` summarizes the architecture, novelty claims and results; open it locally in a browser.
