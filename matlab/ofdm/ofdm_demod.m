function y = ofdm_demod(r, p, fxc)
% OFDM_DEMOD  OFDM baseline demodulator: one N-point FFT, y = F r.
%   r   : N x 1 received frame (prefix removed)
%   p   : parameters (N)
%   fxc : [] for floating point, or fixed-point config
%   y   : N x 1 subcarrier samples
if ~isempty(fxc)
    r = fx(r, fxc.data);
end
y = fft_u(r, false, fxc);
end
