function study_dfts(scen)
% STUDY_DFTS  AFDM against DFT-s-OFDM, the waveform 3GPP kept (with CP-OFDM)
% because it needs the least change to existing hardware. Each waveform is
% run with its cheap receiver and with the full-channel receivers, on
% identical frames, so the BER gap can be set against the hardware gap:
%   DFT-s-OFDM fde     : one-tap equalizer (FFT, N gains, IFFT) - industry receiver
%   DFT-s-OFDM mp-top  : MP on the time-domain channel (S = 16 taps per row)
%   DFT-s-OFDM lmmse   : full-channel LMMSE (upper reference)
%   AFDM       mp-top / lmmse, OFDM fde / lmmse, same meaning
% Fractional delays, genie CSI, no pilots.
%   scen : 'V2X' | 'LEO-S' | 'LEO-Ka'
% Output: results/dfts_<scen>.mat
p     = sys_params(scen);
snr   = 0:4:24;
runs  = {'AFDM', 'mp-top'; 'AFDM', 'lmmse'
         'DFT-s-OFDM', 'fde'; 'DFT-s-OFDM', 'mp-top'; 'DFT-s-OFDM', 'lmmse'
         'OFDM', 'fde'; 'OFDM', 'lmmse'};
base  = struct('S', 16, 'minErrs', 100, 'minFrames', 200, 'maxFrames', 3000, 'seed', 10);
R = cell(size(runs, 1), 1);
for k = 1:size(runs, 1)
    opt = base;  opt.det = runs{k, 2};
    R{k} = ber_curve(p, runs{k, 1}, snr, opt);
    fprintf('%-7s %-10s %-7s BER %s\n', scen, runs{k, 1}, runs{k, 2}, sprintf('%.1e ', R{k}.ber));
end
save(fullfile(results_dir(), ['dfts_' strrep(scen, '-', '') '.mat']), 'scen', 'snr', 'runs', 'R', 'base', 'p');
end
