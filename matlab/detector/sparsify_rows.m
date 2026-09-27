function [idx, val, kept, drop] = sparsify_rows(H, S)
% SPARSIFY_ROWS  Keep the S largest-magnitude taps of every row of H.
%   H    : N x N effective channel
%   S    : taps kept per row (fixed, so the detector datapath is bounded)
%   idx  : N x S column index of each kept tap
%   val  : N x S value of each kept tap
%   kept : fraction of the channel energy that the kept taps hold
%   drop : N x 1 energy of the dropped taps in each row (for unit-energy
%          symbols this is the variance of the interference they cause)
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
drop = max(sum(abs(H).^2, 2) - sum(abs(val).^2, 2), 0);
end
