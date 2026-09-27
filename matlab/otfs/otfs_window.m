function W = otfs_window(p, fxc)
% OTFS_WINDOW  Transmit time-frequency window for pulse-shaped OTFS.
%   p   : parameters (M, K, optional otfsWin = 'sine' (default) | 'tukey')
%   fxc : [] for floating point, or fixed-point config (window ROM: fxc.tw
%         word length with 3 integer bits, since the peak can exceed 2)
%   W   : M x K real window, W(m, n) = wm(m) * wn(n), mean(W(:).^2) = 1
%
% Separable taper along subcarriers and along symbols, applied at the
% transmitter only (receiver noise stays white; the window is part of the
% effective channel). Unit average energy keeps the transmit power equal
% to the other waveforms.
%   'sine'  : full sine taper, sampled at half-integer points. Strong
%             sidelobe suppression, but deep dips at the edges: measured BER
%             loss with a transmit-only window (see results/fairness_*).
%   'tukey' : flat top with raised-cosine edges over 25 % of each axis;
%             mild shaping, close to rectangular.
% A diagonal per-symbol TIME pulse would NOT need this function: it commutes
% with the FFT pair and collapses to the Zak form plus a real scaling
% (checked in test_transforms). Only a TF window forces the three FFT passes.
if isfield(p, 'otfsWin'), kind = p.otfsWin; else, kind = 'sine'; end
switch kind
    case 'sine'
        wm = sin(pi * ((0:p.M - 1).' + 0.5) / p.M);
        wn = sin(pi * ((0:p.K - 1) + 0.5) / p.K);
    case 'tukey'
        wm = tukey_taper(p.M).';
        wn = tukey_taper(p.K);
    otherwise
        error('otfs_window:kind', 'Unknown window "%s".', kind);
end
W  = wm * wn;
W  = W / sqrt(mean(W(:).^2));             % unit average energy
if ~isempty(fxc)
    W = fx(W, struct('W', fxc.tw.W, 'I', 3));
end
end

function w = tukey_taper(L)
% TUKEY_TAPER  Flat window with raised-cosine edges over 25 % of the length
% (12.5 % each side), sampled at half-integer points so no entry is zero.
t = ((0:L - 1) + 0.5) / L;                % position in (0, 1)
r = 0.25;                                 % tapered fraction
w = ones(1, L);
lo = t < r / 2;   hi = t > 1 - r / 2;
w(lo) = 0.5 * (1 - cos(2 * pi * t(lo) / r));
w(hi) = 0.5 * (1 - cos(2 * pi * (1 - t(hi)) / r));
end
