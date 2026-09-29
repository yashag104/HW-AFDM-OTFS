function x = fde_fx(r, w, fxc)
% FDE_FX  DFT-s-OFDM receiver with one-tap equalizer, bit-true with the HLS
% block dfts_fde: FFT, one complex gain per subcarrier, despreading IFFT.
%   r   : N x 1 received frame (prefix removed)
%   w   : N x 1 per-subcarrier gains (MMSE gain with the bias removed, see
%         fde_detector.m); quantized here to fxc.gain
%   fxc : fixed-point config with fields data, tw and gain
%   x   : N x 1 equalized data-symbol estimates
% The product R_k * w_k is exact (both are dyadic with few bits) and is
% rounded once to the data format, as the HLS accumulator does.
R = fft_u(fx(r, fxc.data), false, fxc);      % OFDM FFT
Z = fx(R .* fx(w, fxc.gain), fxc.data);      % one-tap equalizer
x = fft_u(Z, true, fxc);                     % despreading IDFT
end
