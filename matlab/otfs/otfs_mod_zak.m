function s = otfs_mod_zak(x, p, fxc)
% OTFS_MOD_ZAK  OTFS modulator via the inverse discrete Zak transform (IDZT).
%   x   : N x 1 symbols, read as an M x K delay-Doppler grid X(l, k)
%   p   : parameters (M, K)
%   fxc : [] for floating point, or fixed-point config
%   s   : N x 1 time frame, sample index l + M*n (delay l, OTFS symbol n)
%
% With rectangular pulses ISFFT + Heisenberg collapses to one K-point IFFT
% along the Doppler axis of every delay row:  S = X * F_K^H.
X = reshape(x, p.M, p.K);
if ~isempty(fxc)
    X = fx(X, fxc.data);
end
S = fft_cols(X.', true, fxc).';       % IFFT_K on each of the M rows
s = S(:);
end
