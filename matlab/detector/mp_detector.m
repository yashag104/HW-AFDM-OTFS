function [xhat, itersUsed] = mp_detector(y, idx, val, N0, const, mp, isData)
% MP_DETECTOR  Message-passing detector on a sparse effective channel
%              (Raviteja et al., IEEE TWC 2018). Same algorithm for AFDM and OTFS.
%   y     : N x 1 received samples in the detection domain
%   idx   : N x S column index of the taps kept in each row (from sparsify_rows)
%   val   : N x S tap values
%   N0    : noise variance per complex sample: a scalar, or N x 1 per row
%           (noise plus the energy of the taps sparsify dropped from that
%           row, so the detector accounts for the truncation interference)
%   const : Q x 1 constellation
%   mp    : detector settings
%             iter  - maximum number of iterations (bounds the latency)
%             damp  - damping factor in (0, 1]
%             stop  - true: convergence rule below; false: always run iter
%             gamma - a symbol counts as converged when max P >= 1 - gamma
%             eps   - stop when eta drops more than eps below its best value
%   isData: optional N x 1 logical, true for unknown data symbols. Pilot and
%           guard positions are known, so they are left out of the
%           convergence indicator (otherwise eta can never reach 1).
%           Default: all true.
%   xhat      : N x 1 detected symbol indices, 1..Q (from the best iteration)
%   itersUsed : iterations actually run
%
% Factor graph: one edge e per kept tap (observation a = row, variable b = column).
%   Observation -> variable : Gaussian approximation of the interference,
%                             mean mu_e and variance var_e
%   Variable -> observation : probability vector over the Q symbols, P(e, :)
% Convergence indicator eta = fraction of converged symbols. The decision of
% the iteration with the largest eta is kept (Raviteja et al., Sec. III).

[N, S] = size(idx);
Q      = numel(const);
if nargin < 7, isData = true(N, 1); end
nE     = N * S;

ea = repmat((1:N).', S, 1);             % observation (row) of each edge
eb = idx(:);                            % variable (column) of each edge
eh = val(:);                            % channel tap on each edge
ye = y(ea);                             % observation value on each edge

P   = ones(nE, Q) / Q;                  % variable -> observation messages
c   = const(:).';                       % 1 x Q
eh2 = abs(eh).^2;
if isscalar(N0), n0e = N0; else, n0e = N0(ea); end   % noise floor of each edge

etaBest = -1;
xhat    = ones(N, 1);
for it = 1:mp.iter
    % --- observation nodes: interference mean and variance per edge ---
    m1    = P * c.';                              % E[x_b] on each edge
    m2    = P * abs(c.').^2;                      % E[|x_b|^2]
    vx    = max(m2 - abs(m1).^2, 0);              % Var[x_b]
    mu_a  = accumarray(ea, eh .* m1, [N 1]);      % sum over the row
    var_a = accumarray(ea, eh2 .* vx, [N 1]) + N0;
    mu_e  = mu_a(ea) - eh .* m1;                  % remove the own contribution
    var_e = max(var_a(ea) - eh2 .* vx, n0e);

    % --- log-likelihood of every symbol on every edge ---
    LL = -abs(ye - mu_e - eh .* c).^2 ./ var_e;   % nE x Q

    % --- variable nodes: combine all other edges of the same column ---
    Ltot = zeros(N, Q);
    for q = 1:Q
        Ltot(:, q) = accumarray(eb, LL(:, q), [N 1]);
    end
    Lext = Ltot(eb, :) - LL;                      % extrinsic: exclude own edge
    Pnew = exp(Lext - max(Lext, [], 2));
    Pnew = Pnew ./ sum(Pnew, 2);
    P    = mp.damp * Pnew + (1 - mp.damp) * P;

    % --- decision and convergence indicator ---
    Pb        = exp(Ltot - max(Ltot, [], 2));
    Pb        = Pb ./ sum(Pb, 2);
    [pmax, d] = max(Pb, [], 2);
    eta       = mean(pmax(isData) >= 1 - mp.gamma);
    if eta > etaBest
        etaBest = eta;
        xhat    = d;
    end
    if mp.stop && (eta == 1 || eta < etaBest - mp.eps)
        break;
    end
end
itersUsed = it;
end
