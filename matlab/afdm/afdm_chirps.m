function [ch1, ch2] = afdm_chirps(p, fxc)
% AFDM_CHIRPS  Diagonals of the DAFT chirp matrices (the two chirp ROMs).
%   p        : parameters (N, c1, c2)
%   fxc      : [] for floating point, or fixed-point config (uses fxc.chirp)
%   ch1, ch2 : N x 1, ch_i(n+1) = exp(-j 2 pi c_i n^2), n = 0..N-1
% DAFT matrix A = diag(ch2) * F * diag(ch1)  (F = unitary DFT).
n   = (0:p.N - 1).';
ch1 = exp(-1j * 2 * pi * p.c1 * n.^2);
ch2 = exp(-1j * 2 * pi * p.c2 * n.^2);
if ~isempty(fxc)
    ch1 = fx(ch1, fxc.chirp);
    ch2 = fx(ch2, fxc.chirp);
end
end
