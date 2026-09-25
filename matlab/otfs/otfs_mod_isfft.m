function s = otfs_mod_isfft(x, p, fxc)
% OTFS_MOD_ISFFT  OTFS modulator in the two-step form: ISFFT, then Heisenberg.
%   x   : N x 1 symbols, read as an M x K delay-Doppler grid X(l, k)
%   p   : parameters (M, K)
%   fxc : [] for floating point, or fixed-point config
%   s   : N x 1 time frame, sample index l + M*n
%
% ISFFT      : X_TF = F_M * X * F_K^H   (M-point FFT on columns, K-point IFFT on rows)
% Heisenberg : S    = F_M^H * X_TF      (M-point IFFT per OTFS symbol, rectangular pulse)
% Mathematically equal to otfs_mod_zak, but uses three FFT stages; this is
% the structure needed when a non-rectangular pulse or TF window is applied.
X = reshape(x, p.M, p.K);
if ~isempty(fxc)
    X = fx(X, fxc.data);
end
A    = fft_cols(X, false, fxc);            % F_M * X
X_TF = fft_cols(A.', true, fxc).';         % ... * F_K^H
S    = fft_cols(X_TF, true, fxc);          % Heisenberg: F_M^H * X_TF
s    = S(:);
end
