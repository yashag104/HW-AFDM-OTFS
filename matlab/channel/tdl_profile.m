function prof = tdl_profile(name)
% TDL_PROFILE  Tapped-delay-line power delay profile.
%   name : 'NTN-TDL-A' | 'NTN-TDL-B' | 'NTN-TDL-C' | 'NTN-TDL-D' | 'V2X'
%   prof : struct with column vectors
%            delay   - NTN: normalized delay (multiply by delay spread DS)
%                      V2X: delay in seconds (use DS = 1)
%            powerdB - tap power [dB]
%            isLOS   - true for a specular LOS component, false for Rayleigh
%
% NTN tables: 3GPP TR 38.811 Tables 6.9.2-1..4 (as reproduced in arXiv:2602.09834,
% Table I). In the LOS models the first tap is split into a LOS part and a
% Rayleigh part at the same delay; their power ratio is the K-factor
% (TDL-C: 10.224 dB, TDL-D: 11.707 dB).

switch name
    case 'NTN-TDL-A'
        tbl = [0       0        0
               1.0811 -4.675    0
               2.8416 -6.482    0];
    case 'NTN-TDL-B'
        tbl = [0       0        0
               0.7249 -1.973    0
               0.7410 -4.332    0
               5.7392 -11.914   0];
    case 'NTN-TDL-C'
        tbl = [0       -0.394   1
               0       -10.618  0
               14.8124 -23.373  0];
    case 'NTN-TDL-D'
        tbl = [0       -0.284   1
               0       -11.991  0
               0.5596  -9.887   0
               7.3340  -16.771  0];
    case 'V2X'
        % PLACEHOLDER - NOT a verified model. Replace with a published V2X
        % profile (e.g. Acosta-Marum & Ingram VTV-Expressway-Oncoming, or the
        % 3GPP TR 37.885 highway model) before producing any paper results.
        warning('tdl_profile:unverified', 'V2X tap profile is a placeholder.');
        tbl = [0       0        1
               0      -10       0
               100e-9 -3        0
               200e-9 -6        0
               400e-9 -10       0];
    otherwise
        error('tdl_profile:name', 'Unknown profile "%s".', name);
end

prof.delay   = tbl(:, 1);
prof.powerdB = tbl(:, 2);
prof.isLOS   = tbl(:, 3) == 1;
end
