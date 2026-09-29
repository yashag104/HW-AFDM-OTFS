function s = dfts_mod(x, p, fxc)
% DFTS_MOD  DFT-s-OFDM modulator (LTE/NR uplink): N-point DFT spreading, then
% the N-point OFDM IFFT, s = F^H F x.
%   x   : N x 1 data symbols
%   p   : parameters (N)
%   fxc : [] for floating point, or fixed-point config
%   s   : N x 1 time frame (cyclic prefix is added by the channel model)
% All N subcarriers are allocated (same bandwidth, N and prefix as the other
% waveforms), so in floating point the two transforms cancel and the frame is
% single-carrier with a cyclic prefix. Both transforms are still computed:
% a real transmitter needs them for partial allocations, so they are part of
% its hardware cost, and in fixed point each one adds its own rounding.
if ~isempty(fxc)
    x = fx(x, fxc.data);
end
X = fft_u(x, false, fxc);                    % spreading DFT
s = fft_u(X, true, fxc);                     % OFDM IFFT
end
