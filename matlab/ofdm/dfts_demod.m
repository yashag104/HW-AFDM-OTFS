function y = dfts_demod(r, p, fxc)
% DFTS_DEMOD  DFT-s-OFDM demodulator: OFDM FFT, then the despreading IDFT,
% y = F^H F r.
%   r   : N x 1 received frame (prefix removed)
%   p   : parameters (N)
%   fxc : [] for floating point, or fixed-point config
%   y   : N x 1 samples in the data-symbol (time) domain
% The detection domain is therefore the time domain, where the channel is a
% band of delay taps per row. The one-tap equalizer (fde_detector) works
% between the two transforms, on the subcarriers.
if ~isempty(fxc)
    r = fx(r, fxc.data);
end
Y = fft_u(r, false, fxc);                    % OFDM FFT
y = fft_u(Y, true, fxc);                     % despreading IDFT
end
