function y = otfs_demod_zak(r, p, fxc)
% OTFS_DEMOD_ZAK  OTFS demodulator via the discrete Zak transform (DZT).
%   r   : N x 1 received frame (prefix removed)
%   p   : parameters (M, K)
%   fxc : [] for floating point, or fixed-point config
%   y   : N x 1 delay-Doppler samples, vec of the M x K grid
%
% Y = R * F_K : one K-point FFT along every delay row.
R = reshape(r, p.M, p.K);
if ~isempty(fxc)
    R = fx(R, fxc.data);
end
Y = fft_cols(R.', false, fxc).';      % FFT_K on each of the M rows
y = Y(:);
end
