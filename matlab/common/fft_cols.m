function Y = fft_cols(X, inverse, fxc)
% FFT_COLS  Unitary FFT of every column of X (one fft_u call per column).
%   X       : L x C matrix
%   inverse : false = forward, true = inverse
%   fxc     : [] for floating point, or fixed-point config
%   Y       : L x C result
% For a row-wise transform call fft_cols(X.', inverse, fxc).'
Y = zeros(size(X));
for col = 1:size(X, 2)
    Y(:, col) = fft_u(X(:, col), inverse, fxc);
end
end
