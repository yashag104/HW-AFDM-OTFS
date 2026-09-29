# Novelty and claim check (2026-09-29)

Every claim the paper intends to make, the closest prior work found, and a
verdict. Searches: Google-indexed web, arXiv (to 2609.xxxxx), IEEE Xplore
abstracts, Springer/ResearchGate abstracts, Chinese-language web. Papers were
opened and read where the text was reachable; the rest are marked
"abstract only".

Verdicts: **SAFE** (no prior work found), **SAFE IF WORDED AS BELOW**, **WEAK**
(true but not a contribution), **DROP** (already published / false).

---

## 1. Hardware implementations that exist (the prior art to cite)

| Work | What it implements | Receiver in HW? | AFDM? | BER link? | Read |
|---|---|---|---|---|---|
| Hassan et al., *Towards Unified Modulator for Mobility Scenarios: A CGRA-Based Approach*, J. Signal Process. Syst. (Springer), 2026, doi 10.1007/s11265-025-01975-6 | Modulators of OFDM, OTFS, OCDM, AFDM, OTSM on one CGRA (Stratix IV, 170 MHz, 10.88 GOPS, 528 mW) | No (modulators only) | Tx only | No | abstract + snippets (full text paywalled) |
| Shadangi, Das, Chakrabarti, *Low-Complexity VLSI Architecture for OTFS Transceiver Under Multipath Fading Channel*, IEEE TVLSI 32(7), 2024 | OTFS Tx **and Rx**, MMSE equalizer via LU decomposition; BER vs OFDM | **Yes (MMSE)** | No | Yes | abstract |
| C.-H. Yang group (NTU), *A 131mW 6.4Gb/s 256x32 MU-MIMO OTFS Detector*, ISSCC 2024; JSSC 60(9) 2025 | 40-nm ASIC, **message-passing** MU-MIMO OTFS detector | **Yes (MP)** | No | Yes | abstract |
| Isik et al., *FPGA Implementation of OTFS Modulation for 6G*, arXiv:2310.09671 | OTFS modulation on Zynq UltraScale+ RFSoC | not stated | No | – | abstract |
| OTFS transmitter on ZedBoard, J. Signal Process. Syst. 2023 (doi 10.1007/s11265-023-01847-x); Rajangam & Murali, AICSP 128(3) 2026 | OTFS Tx (and "transceiver") FPGA architectures | partly | No | – | abstract |
| Jung, Dubs, Kim, *Bluestein-Based FFT Implementation for Efficient AFDM Modulation*, JCCI 2026 | Bluestein DAFT for arbitrary N; **Python timing only** | No | Tx only, no HW | No | **full text read** |

**Not found anywhere:** an AFDM *receiver* in hardware; an AFDM FPGA synthesis
with resource numbers; any same-platform hardware comparison of AFDM vs OTFS
(or vs OFDM / DFT-s-OFDM); any fixed-point study of AFDM.

**Watch item (scoop risk):** Jung et al. write "Future work will focus on the
fixed-point implementation and real-time hardware validation on the NI
PXIe-7902R FPGA platform." A ResearchGate listing shows the title
"Bluestein-Based DAFT Implementation on FPGA for AFDM Modulation" (July 2026);
its only reachable text is the Python-only JCCI paper, so it is most likely the
same paper retitled. Even if they publish FPGA results, it is an AFDM
*modulator* only: no receiver, no OTFS / DFT-s-OFDM, no BER-vs-cost. Re-check
before submission.

---

## 2. Claim by claim

### C1. "First receiver-inclusive, same-target hardware comparison of AFDM and OTFS (and OFDM, DFT-s-OFDM)"
- Closest: Hassan (modulators only, no BER); Shadangi (OTFS only, MMSE Rx);
  Yang (OTFS only, MP ASIC).
- **Verdict: SAFE IF WORDED AS BELOW.**
  - Say: "first same-platform, receiver-inclusive implementation *comparison*
    of AFDM, OTFS, OFDM and DFT-s-OFDM, linked to BER" and "first reported
    hardware (FPGA) implementation of an AFDM receiver" (still true as of
    2026-09-29).
  - Do **not** say: "first MP detector in hardware" (Yang), "first OTFS
    receiver in hardware" (Shadangi), "first hardware implementation of AFDM
    and OTFS" (Hassan).

### C2. "First hardware measurement of AFDM's marginal cost over OFDM"
- The cost claims are all analytical: Rou et al. arXiv:2602.08163 (Table I:
  OFDM 5N log2 N, AFDM 5N log2 N + 12N, OTFS 5N log2 N + 5N log2 L + 2N;
  "30% overhead at N = 256"; no FPGA/SDR/measurement in the paper, read);
  arXiv:2605.23062 ("one firmware patch"); arXiv:2507.21704 ("cost-effective
  in software-defined radio platforms", cites [14], no hardware data, read);
  arXiv:2606.13416 (standardization, no hardware).
- Our measurement: AFDM mod 833 LUT / 12 DSP / 8 BRAM vs OFDM 677 / 4 / 4
  (+23% LUT, 3x DSP, 2x BRAM, +6 cycles latency) on xc7z020, same flow.
- **Verdict: SAFE.** Strongest single claim. Present as "the first measured
  counterpart to the FLOP-count claim", not as "AFDM is expensive": +23% LUT is
  close to their 30% FLOP figure; the DSP/BRAM ratios are what FLOPs hide.

### C3. "AFDM needs a wider detector (more taps per row) than OTFS under fractional Doppler; cost quantified"
- Leakage itself is known qualitatively (Rou et al. arXiv:2401.07700 v5,
  Dec 2024; OTFS leakage literature). No paper found that quantifies detector
  width (S) vs BER per waveform, or ties it to detector hardware cost.
- **Verdict: SAFE, but moderate.** Must cite 2401.07700 for the leakage
  mechanism. Caveat from our own data: with fractional delays the advantage
  shrinks (V2X ~ equal), so state it per regime.

### C4. "The cost ranking flips with the OTFS pulse assumption"
- 2602.08163 prices OTFS via ISFFT + Heisenberg and notes the single-IDZT form
  (Eq. 35) but keeps "interleaving and reshaping" overhead (read).
  Mohammed, Hadani, Calderbank et al., *Zak-OTFS over CP-OFDM*,
  arXiv:2508.03906 (2025): Zak-OTFS with sinc + time window is "a
  low-complexity precoder over standard CP-OFDM" (abstract read).
- Our measurement: OTFS-Zak 563 LUT / 4 DSP / 2 BRAM, 3098 cycles vs AFDM
  833 / 12 / 8; OTFS-ISFFT 1103 LUT, 8256 cycles.
- **Verdict: SAFE IF WORDED AS BELOW.** The Zak-is-cheap idea is not new
  (cite 2508.03906); the new part is the *measured* same-platform ranking and
  that it reverses the FLOP-based ranking of 2602.08163. Always state the pulse
  assumption next to every OTFS number.

### C5. "First fixed-point / word-length comparison of AFDM, OTFS (and OFDM, DFT-s-OFDM)"
- Nothing found for AFDM; OTFS has low-resolution-ADC *estimation* papers
  (e.g. Southampton TCOM, MIMO OTFS/OTSM with low-resolution ADCs) which are
  not datapath word-length studies. Jung et al. list AFDM fixed-point as
  future work.
- **Verdict: SAFE (time-sensitive).** Cite the low-resolution-ADC OTFS work to
  show the difference (ADC resolution vs internal datapath width).

### C6. "Doppler-rate (LEO) channels"
- Our own result: within-frame Doppler-rate phase <= 2e-3 rad, i.e.
  negligible; the effect is across frames (pre-compensation drift).
  LEO waveform comparisons exist (Mandal et al. arXiv:2602.09834: OTFS/AFDM/OCDM,
  TDL-A..D, BER only, quasi-static; OTFS vs OFDM multiuser LEO arXiv:2403.02012).
- **Verdict: WEAK as a headline.** Keep it as a modelling contribution and a
  justification ("we checked; within-frame rate is negligible, residual CFO
  drift is what matters"), not as a novelty claim.

### C7. AFDM vs DFT-s-OFDM (new direction)
- Haif, Arous, Arslan, *Channel-Aware Waveform Selection Criteria Across
  Different Waveform Domains*, arXiv:2605.01587 (May 2026, abstract read):
  AFDM/OTFS keep their advantage only under sparse, resolvable, stationary
  channels; tuned OFDM / DFT-s-OFDM are more reliable otherwise. Simulation,
  no hardware.
- PAPR: DFT-s-OFDM lowest PAPR is textbook; AFDM PAPR reduction papers exist
  (arXiv:2505.01778, 2606.22464, 2512.17679).
- Hybrids already proposed: DAFT-spread AFDMA (arXiv:2405.03119), DAFT-s-AFDM
  ISAC (2605.19759), Chirped DFT-s-OFDM (2408.06796), DFT-s-OFDM with chirp
  modulation (2508.04075), DFT-s-OFDM with chirping for ISAC (2605.17612);
  arXiv:2606.13416 notes AFDM can be realised through FDSS-based DFT-s-OFDM.
- Random Multiplexing (Liu et al., arXiv:2512.24087): waveform-agnostic
  AMP-based scheme; no DFT-s-OFDM-vs-AFDM same-detector study, no hardware.
- Our results: DFT-s-OFDM + MP ~ AFDM + MP in all three regimes; one-tap FDE
  floors (LEO-Ka ~2e-2, V2X ~4e-2); PAPR 8.0 dB vs 11.5 dB; HW: DFT-s-OFDM
  Rx with FDE 824 LUT / 10 DSP vs AFDM demod 834 / 12.
- **Verdict: SAFE IF WORDED AS BELOW.** "PAPR advantage of DFT-s-OFDM" and
  "OFDM-family can be competitive" are known (cite 2605.01587). New:
  (i) the same-detector comparison showing the gain comes from the receiver,
  not the waveform, and (ii) its hardware price (FDE vs MP) on one FPGA.
  Must discuss the FDSS realisation of AFDM (2606.13416): it means AFDM itself
  can reuse DFT-s-OFDM hardware, which strengthens rather than weakens a
  hardware-cost comparison.

### C8. "A single MP detector cannot run in real time"
- Yang's ASIC reaches 6.4 Gb/s with an MP OTFS detector, so real-time MP is
  clearly possible with enough parallelism.
- **Verdict: DROP as stated.** Replace with a throughput-normalised cost:
  "one MP lane at S = 16 needs ~N*S*passes*iters cycles per frame; real time at
  1.92 MHz needs P lanes; cost scales as ..." and compare with Yang's figures.
  Our MP datapath is a same-datapath reference across waveforms, not a
  state-of-the-art detector; say so.

### C9. Background facts used in the introduction
| Statement | Status | Source |
|---|---|---|
| 3GPP agreed CP-OFDM (DL baseline) and DFT-s-OFDM (UL) for 6G; new waveforms "not precluded" | **Confirmed** (secondary sources) | RAN1#122, Bengaluru, 25–29 Aug 2025; The Mobile Network (Aug 2025); mcns5g.com. Cite the RAN1#122 chair notes from the 3GPP portal (not yet retrieved). |
| Zak-OTFS was presented/supported at RAN1 but not adopted | Confirmed (secondary) | The Mobile Network, Aug 2025 |
| DFT-s-OFDM (SC-FDMA) chosen for the LTE uplink for low PAPR | Standard fact | 3GPP TS 36.211 Rel-8 (2008) |
| DFT-s-OFDM was chosen *instead of* OTFS | **False** – it predates OTFS (2017) by ~9 years; do not write this | – |
| AFDM origin | Bemani, Ksairi, Kountouris, ICC Workshops 2021; IEEE TWC 22(11) 2023 | |
| MP detector | Raviteja et al., IEEE TWC 2018 | |

---

## 3. What the paper can claim (safe wording)

1. First same-platform, receiver-inclusive FPGA comparison of AFDM, OTFS
   (Zak / ISFFT / pulse-shaped), OFDM and DFT-s-OFDM, every hardware number
   tied to a BER curve.
2. First FPGA implementation of an AFDM receiver (DAFT demodulator + MP
   detector), and the first measured counterpart to AFDM's FLOP-based
   "marginal cost" claim.
3. First fixed-point word-length comparison across these waveforms.
4. Measured evidence that the OTFS-vs-AFDM cost ranking depends on the OTFS
   pulse assumption (reverses the FLOP ranking of 2602.08163).
5. Against the 3GPP-retained DFT-s-OFDM: with the same detector the BER gap to
   AFDM largely closes, so AFDM's benefit is a receiver-cost question; we give
   that cost in LUT/DSP/BRAM and PAPR.

The paper stands on the combination; each item alone is modest.

## 4. Must-cite list
Hassan et al. 2026 (CGRA); Shadangi et al. TVLSI 2024; Yang et al. ISSCC 2024 /
JSSC 2025; Jung et al. JCCI 2026; Rou et al. 2401.07700, 2602.08163,
2507.21704, 2605.23062, 2606.13416; Mohammed et al. 2508.03906; Haif et al.
2605.01587; Liu et al. 2512.24087; Mandal et al. 2602.09834; Bemani et al.
TWC 2023; Raviteja et al. TWC 2018; Benzine et al. 2306.07765 (pilot overhead);
RAN1#122 chair notes.

## 5. Open items before submission
- Re-run this check within 2 weeks of submission (AFDM moves fast: ~10 new
  AFDM arXiv papers per month in 2026). Priority targets: Jung/Kim (Hanyang),
  Shadangi/Das (IIT KGP), Yang (NTU), Rou/de Abreu (Constructor Univ.),
  Hassan (CGRA group).
- Get full texts of Hassan (per-waveform numbers), Shadangi (Rx architecture,
  resources), Yang JSSC (MP architecture, lanes) via institute access.
- Retrieve the RAN1#122 chair notes (3GPP portal) for the exact agreement text.
- Replace the V2X placeholder profile before any V2X number is published.
