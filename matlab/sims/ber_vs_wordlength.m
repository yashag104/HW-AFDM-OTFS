% BER_VS_WORDLENGTH  End-to-end BER with fixed-point modulator and demodulator.
% Shows the smallest data word length with no visible BER loss.
% Run from the matlab/ folder:  setup_paths; ber_vs_wordlength
clear;
setup_paths;

p         = sys_params('LEO-Ka');
names     = {'AFDM', 'OTFS-Zak', 'OTFS-ISFFT'};
Wlist     = [6 8 10 12];               % data word lengths [bits]; float is added last
Wrom      = 16;                        % twiddle / chirp ROM width [bits]
snrdB     = 0:4:24;
S         = 16;
nFrames   = 1000;

cfgs = [num2cell(Wlist), {[]}];        % last entry = floating point
ber  = zeros(numel(names), numel(cfgs), numel(snrdB));
for w = 1:numel(names)
    wf = waveform(names{w}, p);
    for c = 1:numel(cfgs)
        if isempty(cfgs{c}), fxc = []; else, fxc = fx_config(cfgs{c}, Wrom, Wrom); end
        for i = 1:numel(snrdB)
            rng(20 + i);               % same frames for every word length
            r = ber_point(p, wf, snrdB(i), S, fxc, nFrames);
            ber(w, c, i) = r.ber;
        end
        if isempty(cfgs{c}), lbl = 'float'; else, lbl = sprintf('W=%d', cfgs{c}); end
        fprintf('%-10s %-6s BER: %s\n', names{w}, lbl, sprintf('%.1e ', ber(w, c, :)));
    end
end

outDir = fullfile(fileparts(mfilename('fullpath')), '..', '..', 'results');
save(fullfile(outDir, 'ber_vs_wordlength.mat'), 'names', 'Wlist', 'Wrom', 'snrdB', 'S', 'ber', ...
     'nFrames', 'p');

% One panel per waveform; line darkness encodes word length (sequential, one hue).
fig = figure('Visible', 'off', 'Position', [100 100 1200 360]);
fig.Theme = 'light';
tl  = tiledlayout(fig, 1, numel(names), 'TileSpacing', 'compact');
floorBer = 1 / (nFrames * 256 * 2);
shade    = linspace(0.75, 0.15, numel(cfgs));       % light (short W) -> dark (float)
for w = 1:numel(names)
    ax = nexttile(tl); hold(ax, 'on');
    st = wf_style(names{w});
    for c = 1:numel(cfgs)
        b = squeeze(ber(w, c, :));  b(b == 0) = NaN;
        col = st.color * (1 - shade(c)) + shade(c) * [1 1 1] * 0.9;
        if isempty(cfgs{c}), lbl = 'float'; else, lbl = sprintf('W = %d', cfgs{c}); end
        plot(ax, snrdB, b, '-', 'Color', col, 'Marker', st.marker, 'MarkerSize', 8, ...
             'LineWidth', 1.5, 'DisplayName', lbl);
    end
    set(ax, 'YScale', 'log'); grid(ax, 'on'); ax.GridAlpha = 0.15; box(ax, 'off');
    ylim(ax, [floorBer 1]); xlim(ax, [snrdB(1) snrdB(end)]);
    xlabel(ax, 'E_s/N_0 [dB]'); ylabel(ax, 'BER');
    title(ax, sprintf('%s (LEO-Ka, ROM %d b)', names{w}, Wrom), 'FontWeight', 'normal');
    legend(ax, 'Location', 'southwest', 'Box', 'off');
end
exportgraphics(fig, fullfile(outDir, 'ber_vs_wordlength.png'), 'Resolution', 200);
fprintf('Saved results/ber_vs_wordlength.mat and .png\n');
