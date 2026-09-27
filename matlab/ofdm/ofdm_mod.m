function s = ofdm_mod(x, p, fxc)
% OFDM_MOD  OFDM baseline modulator: one N-point IFFT, s = F^H x.
%   x   : N x 1 frequency-domain symbols
%   p   : parameters (N)
%   fxc : [] for floating point, or fixed-point config
%   s   : N x 1 time frame (cyclic prefix is added by the channel model)
if ~isempty(fxc)
    x = fx(x, fxc.data);
end
s = fft_u(x, true, fxc);
end
