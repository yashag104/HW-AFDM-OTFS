% BER_VS_TAPS  BER against the number of channel taps per row (S) that the MP
% detector processes. S sets the width of the MP datapath, i.e. its hardware cost.
% Every point reuses the same random frames (paired comparison).
% Run from the matlab/ folder:  setup_paths; ber_vs_taps
clear;
setup_paths;

scen    = {'V2X', 'LEO-S', 'LEO-Ka'};
names   = {'AFDM', 'OTFS-Zak'};
Slist   = [2 3 4 6 8 12 16 24 32];
snrdB   = 18;
nFrames = 2000;

ber  = zeros(numel(scen), numel(names), numel(Slist));
errs = zeros(size(ber));
kept = zeros(size(ber));
for s = 1:numel(scen)
    p = sys_params(scen{s});
    for w = 1:numel(names)
        wf = waveform(names{w}, p);
        for i = 1:numel(Slist)
            rng(200 + s);                             % same frames for every S
            r = ber_point(p, wf, snrdB, Slist(i), [], nFrames);
            ber(s, w, i)  = r.ber;
            errs(s, w, i) = r.errs;
            kept(s, w, i) = r.kept;
        end
        fprintf('%-7s %-9s BER : %s\n', scen{s}, names{w}, sprintf('%.1e ', ber(s, w, :)));
        fprintf('%-7s %-9s kept: %s\n', scen{s}, names{w}, sprintf('%.4f  ', kept(s, w, :)));
    end
end

outDir = fullfile(fileparts(mfilename('fullpath')), '..', '..', 'results');
save(fullfile(outDir, 'ber_vs_taps.mat'), 'scen', 'names', 'Slist', 'snrdB', 'ber', 'errs', ...
     'kept', 'nFrames');

fig = figure('Visible', 'off', 'Position', [100 100 1200 360]);
fig.Theme = 'light';
tl  = tiledlayout(fig, 1, numel(scen), 'TileSpacing', 'compact');
floorBer = 1 / (nFrames * 256 * 2);
for s = 1:numel(scen)
    ax = nexttile(tl); hold(ax, 'on');
    for w = 1:numel(names)
        st = wf_style(names{w});
        b  = squeeze(ber(s, w, :));
        b(b == 0) = NaN;
        plot(ax, Slist, b, 'LineStyle', st.line, 'Color', st.color, 'Marker', st.marker, ...
             'MarkerSize', 8, 'LineWidth', 1.5, 'DisplayName', names{w});
    end
    set(ax, 'YScale', 'log', 'XScale', 'log'); grid(ax, 'on'); ax.GridAlpha = 0.15; box(ax, 'off');
    xticks(ax, Slist); ylim(ax, [floorBer 1]);
    xlabel(ax, 'Detector taps per row S'); ylabel(ax, sprintf('BER at %d dB', snrdB));
    title(ax, scen{s}, 'FontWeight', 'normal');
end
legend(ax, 'Location', 'southwest', 'Box', 'off');
exportgraphics(fig, fullfile(outDir, 'ber_vs_taps.png'), 'Resolution', 200);
fprintf('Saved results/ber_vs_taps.mat and .png\n');
