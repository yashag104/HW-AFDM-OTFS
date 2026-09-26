% PLOT_MP_CONFIG  Figure of the MP detector study (run mp_config_study first).
% BER vs number of iterations at the chosen damping, per regime; the
% horizontal marker is the stopping rule (mean iterations used on its label).
% Run from the matlab/ folder:  setup_paths; plot_mp_config
clear;
setup_paths;
resDir = fullfile(fileparts(mfilename('fullpath')), '..', '..', 'results');
scen   = {'V2X', 'LEO-S', 'LEO-Ka'};
dampSel = 0.7;

fig = figure('Visible', 'off', 'Position', [100 100 1200 360]);
fig.Theme = 'light';
tl  = tiledlayout(fig, 1, numel(scen), 'TileSpacing', 'compact');
for s = 1:numel(scen)
    r  = load(fullfile(resDir, ['mp_config_' strrep(scen{s}, '-', '') '.mat']));
    d  = find(abs(r.damps - dampSel) < 1e-9);
    ax = nexttile(tl); hold(ax, 'on');
    for w = 1:numel(r.names)
        st = wf_style(r.names{w});
        plot(ax, r.iters, squeeze(r.berFixed(w, d, :)), 'LineStyle', st.line, 'Color', st.color, ...
             'Marker', st.marker, 'MarkerSize', 8, 'LineWidth', 1.5, ...
             'DisplayName', sprintf('%s, fixed iterations', r.names{w}));
        plot(ax, r.itStop(w, d), r.berStop(w, d), 'Marker', st.marker, 'MarkerSize', 11, ...
             'MarkerFaceColor', st.color, 'Color', st.color, 'LineStyle', 'none', ...
             'DisplayName', sprintf('%s, stopping rule', r.names{w}));
    end
    % Common range on every panel: differences of a few error events stay small.
    set(ax, 'YScale', 'log'); grid(ax, 'on'); ax.GridAlpha = 0.15; box(ax, 'off');
    ylim(ax, [1e-6 1e-1]); xlim(ax, [0 21]);
    xlabel(ax, 'MP iterations'); ylabel(ax, sprintf('BER at %d dB, S = %d', r.snrdB, r.S));
    title(ax, sprintf('%s (damping %.1f)', scen{s}, dampSel), 'FontWeight', 'normal');
end
lg = legend(ax, 'Orientation', 'horizontal', 'Box', 'off', 'NumColumns', 4);
lg.Layout.Tile = 'south';
exportgraphics(fig, fullfile(resDir, 'mp_config.png'), 'Resolution', 200);
fprintf('Saved results/mp_config.png\n');
