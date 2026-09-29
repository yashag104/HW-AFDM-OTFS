function xhat = fde_detector(y, H, N0, const, spread)
% FDE_DETECTOR  One-tap frequency-domain equalizer, the standard (cheapest)
% receiver of OFDM and DFT-s-OFDM: one complex gain per subcarrier.
%   y      : N x 1 detection-domain samples
%   H      : N x N effective channel (full, from eff_channel)
%   N0     : noise variance per sample
%   const  : Q x 1 constellation (unit average energy)
%   spread : false - OFDM, y is already on the subcarriers
%            true  - DFT-s-OFDM, y is in the time domain: go to the
%                    subcarriers (F), equalize, despread back (F^H)
%   xhat   : N x 1 detected symbol indices, 1..Q
% The per-subcarrier gain d_k is the diagonal of the subcarrier-domain
% channel (the frame-average frequency response). Everything off the
% diagonal is inter-carrier interference from Doppler, which a one-tap
% equalizer cannot undo; that loss is what this detector measures.
N = numel(y);
if spread
    F = fft(eye(N)) / sqrt(N);               % unitary DFT matrix
    d = sum((F * H) .* conj(F), 2);          % diag(F H F^H)
    w = conj(d) ./ (abs(d).^2 + N0);         % MMSE gain per subcarrier
    z = F' * (w .* (F * y));
    xest = z / mean(w .* d);                 % remove the MMSE bias (matters for 16-QAM)
else
    d = diag(H);
    xest = y ./ d;                           % one-tap MMSE, unbiased = zero forcing per subcarrier
end
[~, xhat] = min(abs(xest - const(:).'), [], 2);
end
