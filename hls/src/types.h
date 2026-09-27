// types.h - fixed-point types shared by every block.
// Must match matlab/fixed/fx_config.m:
//   data  : ap_fixed<WD, 3>  (range [-4, 4))
//   ROMs  : ap_fixed<WR, 2>  (twiddles and chirps, range [-2, 2))
// Rounding AP_RND and saturation AP_SAT match matlab/fixed/fx.m.
#pragma once
#include <ap_fixed.h>

#ifndef WD
#define WD 12            // data word length [bits]
#endif
#ifndef WR
#define WR 16            // ROM word length [bits]
#endif

typedef ap_fixed<WD, 3, AP_RND, AP_SAT> data_t;
typedef ap_fixed<WR, 2, AP_RND, AP_SAT> rom_t;
typedef ap_fixed<WR, 3, AP_RND, AP_SAT> win_t;   // OTFS-PS window (peak 2, see otfs_window.m)

// Exact intermediate: holds (data +/- data*rom +/- data*rom) / 2 without rounding.
// Fraction bits: (WD-3) + (WR-2) + 1 = WD+WR-4; integer bits: 3+2+1 (sum) +1 +1 (margin) = 8.
// Also exact for data * win_t: fraction (WD-3) + (WR-3), integer 3 + 3 = 6.
typedef ap_fixed<WD + WR + 4, 8> acc_t;

struct cdata { data_t re, im; };
struct crom  { rom_t  re, im; };

// Frame sizes (matlab/config/sys_params.m)
const int N = 256;       // samples per frame
const int M = 16;        // OTFS delay bins
const int K = 16;        // OTFS Doppler bins
