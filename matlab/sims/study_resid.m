function study_resid(scen)
% STUDY_RESID  Does the MP detector's BER floor come from ignoring the taps it
% drops? Compares MP (S = 16) with and without the truncation-variance
% correction (each row's dropped-tap energy added to its noise variance),
% with and without the pilot/guard layout, against LMMSE. Genie CSI.
%   scen : 'V2X' | 'LEO-S' | 'LEO-Ka'
% Output: results/resid_<scen>.mat
p     = sys_params(scen);
names = {'AFDM', 'OTFS-Zak'};
snr   = [16 20 24];
cfg   = {'mp-top', false, false; 'mp-top', true, false; ...      % det, resid, pilots
         'mp-top', false, true;  'mp-top', true, true;  'lmmse', false, true};
base  = struct('S', 16, 'minErrs', 100, 'minFrames', 300, 'maxFrames', 3000, 'seed', 80);
R = cell(numel(names), size(cfg, 1));
for n = 1:numel(names)
    for k = 1:size(cfg, 1)
        opt = base;  opt.det = cfg{k, 1};  opt.resid = cfg{k, 2};  opt.pilots = cfg{k, 3};
        R{n, k} = ber_curve(p, names{n}, snr, opt);
        fprintf('%-7s %-9s %-6s resid %d pilots %d  BER %s  (errs %s)\n', scen, names{n}, cfg{k, 1}, ...
                cfg{k, 2}, cfg{k, 3}, sprintf('%.1e ', R{n, k}.ber), mat2str(R{n, k}.errs));
    end
end
save(fullfile(results_dir(), ['resid_' strrep(scen, '-', '') '.mat']), 'scen', 'names', 'snr', 'cfg', 'R', 'base');
end
