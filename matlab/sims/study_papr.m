% STUDY_PAPR  PAPR of every waveform (sets the DAC / amplifier back-off and the
% fixed-point headroom). Frames are oversampled 4x by zero-padding in frequency
% so the peaks of the continuous signal are seen.
% Run from the matlab/ folder:  setup_paths; study_papr
clear; rng(60);
setup_paths;
p       = sys_params('LEO-Ka');
names   = {'AFDM', 'OTFS-Zak', 'OTFS-PS', 'OFDM', 'DFT-s-OFDM'};
nFrames = 10000;
os      = 4;                                     % oversampling factor
const   = qam_table(p.Q);
thr     = 0:0.25:13;                             % PAPR thresholds [dB]
ccdf    = zeros(numel(names), numel(thr));
papr    = zeros(numel(names), nFrames);
for n = 1:numel(names)
    wf = waveform(names{n}, p);
    rng(61);                                     % same symbols for every waveform
    for f = 1:nFrames
        s  = wf.ModM * const(randi(p.Q, p.N, 1));
        S  = fft(s);
        Z  = [S(1:p.N / 2); zeros((os - 1) * p.N, 1); S(p.N / 2 + 1:end)];
        so = ifft(Z);
        papr(n, f) = 10 * log10(max(abs(so).^2) / mean(abs(so).^2));
    end
    ccdf(n, :) = mean(papr(n, :).' > thr, 1);
    t = thr(find(ccdf(n, :) < 1e-3, 1));
    if isempty(t)                                % CCDF never drops below 1e-3 on the grid
        tStr = sprintf('> %.2f', thr(end));
    else
        tStr = sprintf('%.2f', t);
    end
    fprintf('%-10s PAPR at CCDF 1e-3: %s dB, mean %.2f dB\n', names{n}, tStr, mean(papr(n, :)));
end
save(fullfile(results_dir(), 'papr.mat'), 'names', 'thr', 'ccdf', 'papr', 'os', 'p');

fig = figure('Visible', 'off', 'Position', [100 100 560 380]);
fig.Theme = 'light';
ax = axes(fig); hold(ax, 'on');
for n = 1:numel(names)
    st = wf_style(names{n});
    c  = ccdf(n, :);  c(c == 0) = NaN;
    plot(ax, thr, c, 'LineStyle', st.line, 'Color', st.color, 'LineWidth', 1.5, 'DisplayName', names{n});
end
set(ax, 'YScale', 'log'); grid(ax, 'on'); ax.GridAlpha = 0.15; box(ax, 'off');
ylim(ax, [1 / nFrames 1]); xlabel(ax, 'PAPR_0 [dB]'); ylabel(ax, 'Pr(PAPR > PAPR_0)');
title(ax, sprintf('PAPR, %dx oversampled, QPSK, N = %d', os, p.N), 'FontWeight', 'normal');
legend(ax, 'Location', 'southwest', 'Box', 'off');
exportgraphics(fig, fullfile(results_dir(), 'papr.png'), 'Resolution', 200);
fprintf('Saved results/papr.mat and .png\n');
