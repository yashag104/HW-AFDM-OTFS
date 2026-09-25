function [idx, val, kept] = sparsify_rows(H, S)
% SPARSIFY_ROWS  Keep the S largest-magnitude taps of every row of H.
%   H    : N x N effective channel
%   S    : taps kept per row (fixed, so the detector datapath is bounded)
%   idx  : N x S column index of each kept tap
%   val  : N x S value of each kept tap
%   kept : fraction of the channel energy that the kept taps hold
% Taps that are dropped act as extra interference for the detector.
N   = size(H, 1);
idx = zeros(N, S);
val = zeros(N, S);
for a = 1:N
    [~, order] = sort(abs(H(a, :)), 'descend');
    idx(a, :)  = order(1:S);
    val(a, :)  = H(a, order(1:S));
end
kept = sum(abs(val(:)).^2) / sum(abs(H(:)).^2);
end
