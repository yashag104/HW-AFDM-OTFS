% BER_VS_SNR  Floating-point BER of AFDM and OTFS in every mobility regime.
% Every (waveform, SNR) point reuses the same random frames (paired comparison).
% Run from the matlab/ folder:  setup_paths; ber_vs_snr
clear;
setup_paths;

scen    = {'V2X', 'LEO-S', 'LEO-Ka'};
names   = {'AFDM', 'OTFS-Zak'};      % OTFS-ISFFT is identical in floating point
snrdB   = 0:3:24;
S       = 16;                        % detector taps per row
nFrames = 2000;

ber  = zeros(numel(scen), numel(names), numel(snrdB));
errs = zeros(size(ber));
for s = 1:numel(scen)
    p = sys_params(scen{s});
    for w = 1:numel(names)
        wf = waveform(names{w}, p);
        for i = 1:numel(snrdB)
            rng(100 * s + i);
            r = ber_point(p, wf, snrdB(i), S, [], nFrames);
            ber(s, w, i)  = r.ber;
            errs(s, w, i) = r.errs;
        end
        fprintf('%-7s %-9s BER: %s\n', scen{s}, names{w}, sprintf('%.1e ', ber(s, w, :)));
    end
end

outDir = fullfile(fileparts(mfilename('fullpath')), '..', '..', 'results');
save(fullfile(outDir, 'ber_vs_snr.mat'), 'scen', 'names', 'snrdB', 'S', 'ber', 'errs', 'nFrames');

fig = figure('Visible', 'off', 'Position', [100 100 1200 360]);
fig.Theme = 'light';
tl  = tiledlayout(fig, 1, numel(scen), 'TileSpacing', 'compact');
floorBer = 1 / (nFrames * 256 * 2);                  % one error in the whole run
for s = 1:numel(scen)
    ax = nexttile(tl); hold(ax, 'on');
    for w = 1:numel(names)
        st = wf_style(names{w});
        b  = squeeze(ber(s, w, :));
        b(b == 0) = NaN;                              % zero errors: not plotted
        plot(ax, snrdB, b, 'LineStyle', st.line, 'Color', st.color, 'Marker', st.marker, ...
             'MarkerSize', 8, 'LineWidth', 1.5, 'DisplayName', names{w});
    end
    set(ax, 'YScale', 'log'); grid(ax, 'on'); ax.GridAlpha = 0.15; box(ax, 'off');
    ylim(ax, [floorBer 1]); xlim(ax, [snrdB(1) snrdB(end)]);
    xlabel(ax, 'E_s/N_0 [dB]'); ylabel(ax, 'BER');
    title(ax, scen{s}, 'FontWeight', 'normal');
end
legend(ax, 'Location', 'southwest', 'Box', 'off');
exportgraphics(fig, fullfile(outDir, 'ber_vs_snr.png'), 'Resolution', 200);
fprintf('Saved results/ber_vs_snr.mat and .png\n');
