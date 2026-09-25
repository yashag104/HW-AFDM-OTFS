function s = afdm_mod(x, p, fxc)
% AFDM_MOD  AFDM modulator: inverse DAFT, s = A^H x.
%   x   : N x 1 symbols in the affine (chirp) domain
%   p   : parameters from sys_params
%   fxc : [] for floating point, or fixed-point config
%   s   : N x 1 time-domain frame (prefix is added by the channel model)
%
% A^H = diag(conj(ch1)) * F^H * diag(conj(ch2)):
%   pre-chirp (c2)  ->  N-point IFFT  ->  post-chirp (c1)
[ch1, ch2] = afdm_chirps(p, fxc);
if isempty(fxc)
    s = conj(ch1) .* fft_u(conj(ch2) .* x, true, []);
else
    u = fx(fx(x, fxc.data) .* conj(ch2), fxc.data);
    v = fft_u(u, true, fxc);
    s = fx(v .* conj(ch1), fxc.data);
end
end
