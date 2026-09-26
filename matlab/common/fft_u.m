function X = fft_u(x, inverse, fxc)
% FFT_U  Unitary FFT of a column vector, in floating or fixed point.
%   x       : L x 1 column vector (L a power of two)
%   inverse : false = forward DFT, true = inverse DFT
%   fxc     : [] for floating point, or fixed-point config (see fx_config)
%   X       : L x 1 unitary transform, (1/sqrt(L)) * sum x exp(-/+ j 2 pi k n / L)

L = numel(x);
if isempty(fxc)
    if inverse
        X = ifft(x) * sqrt(L);
    else
        X = fft(x) / sqrt(L);
    end
else
    % Divide by 2 in every other stage: 2^(-log2(L)/2) = 1/sqrt(L).
    nStages = log2(L);
    assert(mod(nStages, 2) == 0, 'fft_u: fixed point needs an even number of stages.');
    sched = mod(0:nStages - 1, 2) == 0;
    X = fft_fx(x, inverse, fxc.data, fxc.tw, sched);
end
end
