function study_fairness(scen)
% STUDY_FAIRNESS  Is the AFDM/OTFS BER gap real or an artifact of the MP tap
% truncation? Every waveform is run with three detectors on identical frames:
%   mp-top  : MP with the S = 16 largest taps per row (hardware baseline)
%   mp-path : MP with w = 5 taps per path per row (AFDM literature selection)
%   lmmse   : LMMSE on the full channel (no truncation at all)
% Fractional delays, genie CSI, no pilots.
%   scen : 'V2X' | 'LEO-S' | 'LEO-Ka'
% Output: results/fairness_<scen>.mat
p     = sys_params(scen);
snr   = 0:4:24;
runs  = {'AFDM', 'mp-top'; 'AFDM', 'mp-path'; 'AFDM', 'lmmse'
         'OTFS-Zak', 'mp-top'; 'OTFS-Zak', 'mp-path'; 'OTFS-Zak', 'lmmse'
         'OTFS-PS', 'mp-top'; 'OTFS-PS', 'lmmse'
         'OFDM', 'lmmse'};
base  = struct('S', 16, 'w', 5, 'minErrs', 100, 'minFrames', 200, 'maxFrames', 3000, 'seed', 10);
R = cell(size(runs, 1), 1);
for k = 1:size(runs, 1)
    opt = base;  opt.det = runs{k, 2};
    R{k} = ber_curve(p, runs{k, 1}, snr, opt);
    fprintf('%-7s %-9s %-8s BER %s\n', scen, runs{k, 1}, runs{k, 2}, sprintf('%.1e ', R{k}.ber));
end
save(fullfile(results_dir(), ['fairness_' strrep(scen, '-', '') '.mat']), 'scen', 'snr', 'runs', 'R', 'base', 'p');
end
