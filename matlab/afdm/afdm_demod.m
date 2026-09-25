function y = afdm_demod(r, p, fxc)
% AFDM_DEMOD  AFDM demodulator: DAFT, y = A r.
%   r   : N x 1 received frame (prefix removed)
%   p   : parameters from sys_params
%   fxc : [] for floating point, or fixed-point config
%   y   : N x 1 affine-domain samples
%
% A = diag(ch2) * F * diag(ch1):
%   chirp (c1)  ->  N-point FFT  ->  chirp (c2)
[ch1, ch2] = afdm_chirps(p, fxc);
if isempty(fxc)
    y = ch2 .* fft_u(ch1 .* r, false, []);
else
    u = fx(fx(r, fxc.data) .* ch1, fxc.data);
    v = fft_u(u, false, fxc);
    y = fx(v .* ch2, fxc.data);
end
end
