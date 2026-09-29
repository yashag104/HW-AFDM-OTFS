function plot_studies(which)
% PLOT_STUDIES  Figures for the saved study results (results/*.mat -> results/*.png).
%   which : 'fairness' | 'taps' | 'estimation' | 'wordlength' | 'dfts'
% Every point carries its 95 % confidence interval; V2X panels are marked
% because the V2X tap profile is still a placeholder.
switch which
    case 'fairness',   fairness();
    case 'taps',       taps();
    case 'estimation', estimation();
    case 'wordlength', wordlength();
    case 'dfts',       dfts();
    otherwise, error('plot_studies:which', 'Unknown figure "%s".', which);
end
end

% ---------------------------------------------------------------------------
function fairness()
scen = {'V2X', 'LEO-S', 'LEO-Ka'};
dets = {'mp-top', 'mp-path', 'lmmse'};
detTitle = {'MP, S = 16 largest taps', 'MP, 5 taps per path', 'LMMSE, full channel'};
[fig, tl] = new_figure(3, 3, 1250, 950);
for s = 1:3
    d = load(fullfile(results_dir(), ['fairness_' strrep(scen{s}, '-', '') '.mat']));
    for c = 1:3
        ax = nexttile(tl); hold(ax, 'on');
        for k = find(strcmp(d.runs(:, 2), dets{c})).'
            plot_ber(ax, d.snr, d.R{k}, d.runs{k, 1}, d.runs{k, 1});
        end
        style_axes(ax, [d.snr(1) d.snr(end)], 'E_s/N_0 [dB]');
        title(ax, sprintf('%s - %s', panel_name(scen{s}), detTitle{c}), 'FontWeight', 'normal');
        if s == 1 && c == 3, legend(ax, 'Location', 'southwest', 'Box', 'off'); end
    end
end
save_figure(fig, 'fairness');
end

% ---------------------------------------------------------------------------
function taps()
scen = {'V2X', 'LEO-S', 'LEO-Ka'};
[fig, tl] = new_figure(3, 2, 1000, 950);
for s = 1:3
    d = load(fullfile(results_dir(), ['taps_' strrep(scen{s}, '-', '') '.mat']));
    ax = nexttile(tl); hold(ax, 'on');
    for n = 1:numel(d.names)
        plot_ber(ax, d.Slist, [d.top{n, :}], d.names{n}, d.names{n});
    end
    style_axes(ax, [d.Slist(1) d.Slist(end)], 'Detector taps per row S (S largest)');
    set(ax, 'XScale', 'log'); xticks(ax, d.Slist);
    title(ax, sprintf('%s - MP, S largest taps, %d dB', panel_name(scen{s}), d.snrdB), 'FontWeight', 'normal');
    if s == 1, legend(ax, 'Location', 'southwest', 'Box', 'off'); end
    ax = nexttile(tl); hold(ax, 'on');
    for n = 1:numel(d.names)
        plot_ber(ax, d.nPaths * d.wlist, [d.path{n, :}], d.names{n}, d.names{n});
    end
    style_axes(ax, d.nPaths * [d.wlist(1) d.wlist(end)], sprintf('Detector taps per row S = %d paths x w', d.nPaths));
    xticks(ax, d.nPaths * d.wlist);
    title(ax, sprintf('%s - MP, w taps per path, %d dB', panel_name(scen{s}), d.snrdB), 'FontWeight', 'normal');
end
save_figure(fig, 'taps');
end

% ---------------------------------------------------------------------------
function estimation()
scen = {'V2X', 'LEO-Ka'};
[fig, tl] = new_figure(1, 2, 1150, 420);
for s = 1:2
    d = load(fullfile(results_dir(), ['estimation_' strrep(scen{s}, '-', '') '.mat']));
    ax = nexttile(tl); hold(ax, 'on');
    for n = 1:numel(d.names)
        frac = d.R{n, 1}.dataFrac;
        plot_ber(ax, d.snr, d.R{n, 1}, d.names{n}, sprintf('%s, genie CSI (%d%% data)', d.names{n}, round(100 * frac)), true);
        plot_ber(ax, d.snr, d.R{n, 2}, d.names{n}, sprintf('%s, estimated CSI, MP', d.names{n}));
    end
    style_axes(ax, [d.snr(1) d.snr(end)], 'E_s/N_0 [dB]');
    title(ax, sprintf('%s - pilot-based channel estimation', panel_name(scen{s})), 'FontWeight', 'normal');
    legend(ax, 'Location', 'southwest', 'Box', 'off', 'FontSize', 8);
end
save_figure(fig, 'estimation');
end

% ---------------------------------------------------------------------------
function wordlength()
d = load(fullfile(results_dir(), 'wordlength_LEOKa.mat'));
[fig, tl] = new_figure(1, numel(d.names), 1500, 380);
labels = [arrayfun(@(w) sprintf('W = %d', w), d.Wlist, 'UniformOutput', false), {'float'}];
for n = 1:numel(d.names)
    ax = nexttile(tl); hold(ax, 'on');
    for c = 1:numel(labels)
        plot_ber(ax, d.snr, d.R{n, c}, d.names{n}, labels{c}, c < numel(labels) - 1);
    end
    style_axes(ax, [d.snr(1) d.snr(end)], 'E_s/N_0 [dB]');
    title(ax, sprintf('%s (LEO-Ka, ROM %d b)', d.names{n}, d.Wrom), 'FontWeight', 'normal');
    legend(ax, 'Location', 'southwest', 'Box', 'off', 'FontSize', 8);
end
save_figure(fig, 'wordlength');
end

% ---------------------------------------------------------------------------
function dfts()
% AFDM against DFT-s-OFDM: both with MP (same detector datapath), and the
% one-tap FDE receivers (lighter) that OFDM-family hardware actually ships.
scen  = {'V2X', 'LEO-S', 'LEO-Ka'};
curve = {'AFDM', 'mp-top', 'AFDM, MP', false
         'DFT-s-OFDM', 'mp-top', 'DFT-s-OFDM, MP', false
         'DFT-s-OFDM', 'fde', 'DFT-s-OFDM, one-tap FDE', true
         'OFDM', 'fde', 'OFDM, one-tap FDE', true};
[fig, tl] = new_figure(1, 3, 1500, 420);
for s = 1:3
    d = load(fullfile(results_dir(), ['dfts_' strrep(scen{s}, '-', '') '.mat']));
    ax = nexttile(tl); hold(ax, 'on');
    for c = 1:size(curve, 1)
        k = find(strcmp(d.runs(:, 1), curve{c, 1}) & strcmp(d.runs(:, 2), curve{c, 2}));
        plot_ber(ax, d.snr, d.R{k}, curve{c, 1}, curve{c, 3}, curve{c, 4});
    end
    style_axes(ax, [d.snr(1) d.snr(end)], 'E_s/N_0 [dB]');
    title(ax, panel_name(scen{s}), 'FontWeight', 'normal');
    if s == 1, legend(ax, 'Location', 'southwest', 'Box', 'off', 'FontSize', 8); end
end
save_figure(fig, 'dfts');
end

% ---------------------------------------------------------------------------
function [fig, tl] = new_figure(rows, cols, w, h)
fig = figure('Visible', 'off', 'Position', [100 100 w h]);
fig.Theme = 'light';
tl  = tiledlayout(fig, rows, cols, 'TileSpacing', 'compact', 'Padding', 'compact');
end

function style_axes(ax, xl, xlab)
set(ax, 'YScale', 'log'); grid(ax, 'on'); ax.GridAlpha = 0.15; box(ax, 'off');
ylim(ax, [1e-6 1]); xlim(ax, xl);
xlabel(ax, xlab); ylabel(ax, 'BER');
end

function t = panel_name(scen)
if strcmp(scen, 'V2X'), t = 'V2X (placeholder profile)'; else, t = scen; end
end

function save_figure(fig, name)
exportgraphics(fig, fullfile(results_dir(), [name '.png']), 'Resolution', 180);
fprintf('Saved results/%s.png\n', name);
end
