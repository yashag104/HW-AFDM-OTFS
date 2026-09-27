function [idx, val, kept, drop] = sparsify_paths(Hpaths, H, w)
% SPARSIFY_PATHS  Structured tap selection: w taps per path in every row.
%   Hpaths : 1 x P cell, Hpaths{k} = effective channel of path k alone
%   H      : N x N total effective channel (sum of the paths)
%   w      : taps kept per path and row (AFDM literature: 2*xi + 1 around the peak)
%   idx    : N x S column indices, S = P * w
%   val    : N x S values taken from the total channel H
%   kept   : fraction of the channel energy held by the kept taps
%   drop   : N x 1 energy of the dropped taps in each row
%
% For every row, the w largest taps of EACH path are kept (their union);
% rows where paths overlap are padded with the next largest taps of H.
% Compared with sparsify_rows (S largest of the total), a weak path always
% keeps its own taps instead of losing them to a strong path's leakage.
P   = numel(Hpaths);
N   = size(H, 1);
S   = P * w;
idx = zeros(N, S);
val = zeros(N, S);
for a = 1:N
    pick = [];
    for k = 1:P
        [~, o] = sort(abs(Hpaths{k}(a, :)), 'descend');
        pick   = [pick, o(1:w)];                 %#ok<AGROW>
    end
    pick = unique(pick, 'stable');
    if numel(pick) < S                           % pad with the next largest of H
        [~, o] = sort(abs(H(a, :)), 'descend');
        o      = o(~ismember(o, pick));
        pick   = [pick, o(1:S - numel(pick))];   %#ok<AGROW>
    end
    idx(a, :) = pick(1:S);
    val(a, :) = H(a, pick(1:S));
end
kept = sum(abs(val(:)).^2) / sum(abs(H(:)).^2);
drop = max(sum(abs(H).^2, 2) - sum(abs(val).^2, 2), 0);
end
