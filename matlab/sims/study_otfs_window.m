function study_otfs_window(scen)
% STUDY_OTFS_WINDOW  Pulse-shaped OTFS: how much BER does the transmit TF
% window cost? Rectangular (Zak) vs mild 'tukey' vs strong 'sine' window,
% with MP (S = 16) and LMMSE. Same frames everywhere; fractional delays.
%   scen : 'V2X' | 'LEO-S' | 'LEO-Ka'
% Output: results/otfs_window_<scen>.mat
snr  = 0:4:24;
base = struct('S', 16, 'minErrs', 100, 'minFrames', 200, 'maxFrames', 3000, 'seed', 10);
cfg  = {'OTFS-Zak', 'none'; 'OTFS-PS', 'tukey'; 'OTFS-PS', 'sine'};
dets = {'mp-top', 'lmmse'};
R = cell(size(cfg, 1), numel(dets));
for k = 1:size(cfg, 1)
    p = sys_params(scen);
    p.otfsWin = cfg{k, 2};
    for d = 1:numel(dets)
        opt = base;  opt.det = dets{d};
        R{k, d} = ber_curve(p, cfg{k, 1}, snr, opt);
        fprintf('%-7s %-9s %-6s %-7s BER %s\n', scen, cfg{k, 1}, cfg{k, 2}, dets{d}, sprintf('%.1e ', R{k, d}.ber));
    end
end
save(fullfile(results_dir(), ['otfs_window_' strrep(scen, '-', '') '.mat']), 'scen', 'snr', 'cfg', 'dets', 'R', 'base');
end
