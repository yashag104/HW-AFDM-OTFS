function xhat = lmmse_detector(y, H, N0, const)
% LMMSE_DETECTOR  Linear MMSE equalizer with hard decisions (reference detector).
%   y     : N x 1 received samples (pilot contribution already removed)
%   H     : N x D effective channel of the D data symbols (full, not truncated)
%   N0    : noise variance per sample
%   const : Q x 1 constellation (unit average energy)
%   xhat  : D x 1 detected symbol indices, 1..Q
% x_est = (H^H H + N0 I)^-1 H^H y. Uses every channel tap, so it shows how
% much of any BER difference comes from the MP detector's tap truncation.
D    = size(H, 2);
xest = (H' * H + N0 * eye(D)) \ (H' * y);
[~, xhat] = min(abs(xest - const(:).'), [], 2);
end
