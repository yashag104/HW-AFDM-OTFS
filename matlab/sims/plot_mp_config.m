% PLOT_MP_CONFIG  Figure and table of the MP detector study (run mp_config_study first).
% BER vs number of iterations (no stopping) at 12 dB (faded) and 18 dB, with
% the stopping rule at the default gamma / eps as filled markers at their
% mean iteration count. Also prints the gamma x eps grid.
% Run from the matlab/ folder:  setup_paths; plot_mp_config
clear;
setup_paths;
scen = {'V2X', 'LEO-Ka'};
fig = figure('Visible', 'off', 'Position', [100 100 1000 380]);
fig.Theme = 'light';
tl = tiledlayout(fig, 1, numel(scen), 'TileSpacing', 'compact');
for s = 1:numel(scen)
    d  = load(fullfile(results_dir(), ['mp_config_' strrep(scen{s}, '-', '') '.mat']));
    ga = find(abs(d.gammas - 0.01) < 1e-12);  eb = find(abs(d.epss - 0.2) < 1e-12);
    ax = nexttile(tl); hold(ax, 'on');
    for n = 1:numel(d.names)
        st = wf_style(d.names{n});
        for q = 1:numel(d.snr)
            col = st.color;  if q == 1, col = 0.45 * col + 0.55; end
            plot(ax, d.iters, squeeze(d.berFixed(n, q, :)), 'LineStyle', st.line, 'Color', col, ...
                 'Marker', st.marker, 'MarkerSize', 7, 'LineWidth', 1.4, ...
                 'DisplayName', sprintf('%s, %d dB, fixed iterations', d.names{n}, d.snr(q)));
            plot(ax, d.itStop(n, q, ga, eb), d.berStop(n, q, ga, eb), 'Marker', st.marker, ...
                 'MarkerSize', 10, 'MarkerFaceColor', col, 'Color', col, 'LineStyle', 'none', ...
                 'DisplayName', sprintf('%s, %d dB, stopping rule', d.names{n}, d.snr(q)));
        end
    end
    set(ax, 'YScale', 'log'); grid(ax, 'on'); ax.GridAlpha = 0.15; box(ax, 'off');
    ylim(ax, [1e-6 1e-1]); xlim(ax, [0 21]);
    xlabel(ax, 'MP iterations'); ylabel(ax, 'BER (S = 16)');
    t = scen{s};  if strcmp(t, 'V2X'), t = 'V2X (placeholder profile)'; end
    title(ax, t, 'FontWeight', 'normal');

    fprintf('\n%s: stopping rule, BER (mean iterations), rows gamma, columns eps %s\n', scen{s}, mat2str(d.epss));
    for n = 1:numel(d.names)
        for q = 1:numel(d.snr)
            fprintf('  %-9s %2d dB\n', d.names{n}, d.snr(q));
            for a = 1:numel(d.gammas)
                fprintf('    gamma %-6g', d.gammas(a));
                for b = 1:numel(d.epss)
                    fprintf('  %.1e (%4.1f)', d.berStop(n, q, a, b), d.itStop(n, q, a, b));
                end
                fprintf('\n');
            end
        end
    end
end
lg = legend(ax, 'NumColumns', 2, 'Box', 'off');
lg.Layout.Tile = 'east';
exportgraphics(fig, fullfile(results_dir(), 'mp_config.png'), 'Resolution', 180);
fprintf('\nSaved results/mp_config.png\n');
