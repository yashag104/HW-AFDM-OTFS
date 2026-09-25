function y = otfs_demod_sfft(r, p, fxc)
% OTFS_DEMOD_SFFT  OTFS demodulator in the two-step form: Wigner, then SFFT.
%   r   : N x 1 received frame (prefix removed)
%   p   : parameters (M, K)
%   fxc : [] for floating point, or fixed-point config
%   y   : N x 1 delay-Doppler samples, vec of the M x K grid
%
% Wigner : Y_TF = F_M * R              (M-point FFT per OTFS symbol)
% SFFT   : Y    = F_M^H * Y_TF * F_K   (M-point IFFT on columns, K-point FFT on rows)
R = reshape(r, p.M, p.K);
if ~isempty(fxc)
    R = fx(R, fxc.data);
end
Y_TF = fft_cols(R, false, fxc);            % Wigner
B    = fft_cols(Y_TF, true, fxc);          % F_M^H * Y_TF
Y    = fft_cols(B.', false, fxc).';        % ... * F_K
y    = Y(:);
end
