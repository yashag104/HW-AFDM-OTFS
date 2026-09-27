function study_estimation(scen)
% STUDY_ESTIMATION  Pilot-based channel estimation instead of genie CSI.
% Each waveform uses its own pilot/guard layout (pilot_layout.m) and the same
% OMP estimator. Curves: genie CSI with the same pilot overhead (isolates the
% estimation loss), estimated CSI with MP (S = 16), estimated CSI with LMMSE.
% The data share of the frame differs per waveform and is saved as dataFrac.
%   scen : 'V2X' | 'LEO-S' | 'LEO-Ka'
% Output: results/estimation_<scen>.mat
p     = sys_params(scen);
names = {'AFDM', 'OTFS-Zak', 'OTFS-PS'};
snr   = 0:4:24;
modes = {'genie', 'mp-top'; 'est', 'mp-top'; 'est', 'lmmse'};
base  = struct('S', 16, 'pilots', true, 'minErrs', 100, 'minFrames', 200, 'maxFrames', 3000, 'seed', 30);
R = cell(numel(names), size(modes, 1));
for n = 1:numel(names)
    for k = 1:size(modes, 1)
        opt = base;  opt.csi = modes{k, 1};  opt.det = modes{k, 2};
        R{n, k} = ber_curve(p, names{n}, snr, opt);
        fprintf('%-7s %-9s %-5s %-7s data %.2f BER %s\n', scen, names{n}, modes{k, 1}, modes{k, 2}, ...
                R{n, k}.dataFrac, sprintf('%.1e ', R{n, k}.ber));
    end
end
save(fullfile(results_dir(), ['estimation_' strrep(scen, '-', '') '.mat']), 'scen', 'names', 'snr', ...
     'modes', 'R', 'base', 'p');
end
