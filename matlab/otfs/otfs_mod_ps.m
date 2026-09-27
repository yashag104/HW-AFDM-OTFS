function s = otfs_mod_ps(x, p, fxc)
% OTFS_MOD_PS  Pulse-shaped OTFS modulator: ISFFT, TF window, Heisenberg.
%   x   : N x 1 symbols, read as an M x K delay-Doppler grid X(l, k)
%   p   : parameters (M, K)
%   fxc : [] for floating point, or fixed-point config
%   s   : N x 1 time frame, sample index l + M*n
%
% The window sits between the ISFFT and the Heisenberg transform, so the
% three FFT passes can no longer collapse into the single Zak pass.
% The matching demodulator is otfs_demod_sfft (rectangular receive window).
X = reshape(x, p.M, p.K);
if ~isempty(fxc)
    X = fx(X, fxc.data);
end
W    = otfs_window(p, fxc);
A    = fft_cols(X, false, fxc);            % ISFFT: F_M * X
X_TF = fft_cols(A.', true, fxc).';         %        ... * F_K^H
X_TF = X_TF .* W;                          % TF window (real multiply per sample)
if ~isempty(fxc)
    X_TF = fx(X_TF, fxc.data);
end
S    = fft_cols(X_TF, true, fxc);          % Heisenberg: F_M^H * X_TF
s    = S(:);
end
