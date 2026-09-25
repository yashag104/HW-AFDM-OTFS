% SWEEP_SQNR  Word-length sweep: SQNR of every transform block, Tx and Rx.
% Each block is fed the same input in floating and fixed point; SQNR compares
% the two outputs. Rx blocks see a realistic input: LEO-Ka channel + noise.
% Run from the matlab/ folder:  setup_paths; sweep_sqnr
clear; rng(2);
setup_paths;

p       = sys_params('LEO-Ka');
p.Q     = 16;                       % 16-QAM: the more demanding input
names   = {'AFDM', 'OTFS-Zak', 'OTFS-ISFFT'};
Wdata   = 8:2:22;                   % data word lengths swept [bits]
Wrom    = 18;                       % twiddle / chirp ROM width while sweeping data
nFrames = 40;                       % frames averaged per point
snrRxdB = 30;                       % SNR of the Rx test signal [dB]
const   = qam_table(p.Q);

sqnr = zeros(numel(names), 2, numel(Wdata));      % (waveform, Tx/Rx, W)
nSat = zeros(numel(names), 2, numel(Wdata));      % samples at the saturation limit
lim  = 2^(fx_config(8, 8, 8).data.I - 1);         % |value| limit of the data format
for w = 1:numel(names)
    wf = waveform(names{w}, p);
    for iw = 1:numel(Wdata)
        rng(3);                  % identical frames for every waveform and word length
        fxc = fx_config(Wdata(iw), Wrom, Wrom);
        sig = zeros(2, 1);   err = zeros(2, 1);
        for f = 1:nFrames
            x   = const(randi(p.Q, p.N, 1));
            ch  = gen_channel(p);
            r   = apply_channel(wf.mod(x, []), wf.pre, ch, p, 0);
            r   = r + sqrt(10^(-snrRxdB / 10) / 2) * (randn(p.N, 1) + 1j * randn(p.N, 1));
            xq  = fx(x, fxc.data);                 % both paths get the same input
            rq  = fx(r, fxc.data);
            refTx = wf.mod(xq, []);   gotTx = wf.mod(xq, fxc);
            refRx = wf.demod(rq, []); gotRx = wf.demod(rq, fxc);
            sig = sig + [sum(abs(refTx).^2); sum(abs(refRx).^2)];
            err = err + [sum(abs(gotTx - refTx).^2); sum(abs(gotRx - refRx).^2)];
            satTx = abs(real(refTx)) >= lim | abs(imag(refTx)) >= lim;
            satRx = abs(real(refRx)) >= lim | abs(imag(refRx)) >= lim;
            nSat(w, :, iw) = nSat(w, :, iw) + [sum(satTx), sum(satRx)];
        end
        sqnr(w, :, iw) = 10 * log10(sig ./ err);
    end
    fprintf('%-10s done\n', names{w});
end

% ---- Table ----
fprintf('\nSQNR [dB], ROM = %d bits\n%-6s', Wrom, 'W');
for w = 1:numel(names), fprintf('%12s-Tx %12s-Rx', names{w}, names{w}); end
fprintf('\n');
for iw = 1:numel(Wdata)
    fprintf('%-6d', Wdata(iw));
    fprintf('%15.1f', squeeze(sqnr(:, :, iw)).');
    fprintf('\n');
end

fprintf('\nOutput samples beyond the data range (+/-%d), out of %d per block:\n', lim, nFrames * p.N);
for w = 1:numel(names)
    fprintf('%-10s Tx %d, Rx %d\n', names{w}, nSat(w, 1, 1), nSat(w, 2, 1));
end

% ---- Save ----
outDir = fullfile(fileparts(mfilename('fullpath')), '..', '..', 'results');
if ~exist(outDir, 'dir'), mkdir(outDir); end
save(fullfile(outDir, 'sqnr_sweep.mat'), 'Wdata', 'Wrom', 'names', 'sqnr', 'p');

% ---- Figure: one panel for Tx, one for Rx (same y axis) ----
fig = figure('Visible', 'off', 'Position', [100 100 900 360]);
fig.Theme = 'light';                       % paper figures: white background
tl  = tiledlayout(fig, 1, 2, 'TileSpacing', 'compact');
titles = {'Modulator (Tx)', 'Demodulator (Rx)'};
for side = 1:2
    ax = nexttile(tl); hold(ax, 'on');
    for w = 1:numel(names)
        st = wf_style(names{w});
        plot(ax, Wdata, squeeze(sqnr(w, side, :)), 'LineStyle', st.line, 'Color', st.color, ...
             'Marker', st.marker, 'MarkerSize', 8, 'LineWidth', 1.5, 'DisplayName', names{w});
    end
    grid(ax, 'on'); ax.GridAlpha = 0.15; box(ax, 'off');
    xlabel(ax, 'Data word length W [bits]'); ylabel(ax, 'SQNR [dB]');
    title(ax, titles{side}, 'FontWeight', 'normal');
    ylim(ax, [0 max(sqnr(:)) + 5]);
    xlim(ax, [Wdata(1) - 1, Wdata(end) + 1]);
end
legend(ax, 'Location', 'southeast', 'Box', 'off');
exportgraphics(fig, fullfile(outDir, 'sqnr_sweep.png'), 'Resolution', 200);
fprintf('\nSaved results/sqnr_sweep.mat and results/sqnr_sweep.png\n');
