function est = omp_estimate(yObs, dict, N0, Pmax)
% OMP_ESTIMATE  Estimate the channel paths from the pilot region (orthogonal
% matching pursuit on the delay-Doppler grid).
%   yObs : received samples at lay.obsIdx (pilot response + noise + data leakage)
%   dict : dictionary from build_dictionary
%   N0   : noise variance per sample
%   Pmax : maximum number of paths to extract
%   est  : estimated channel in gen_channel format (h, tau, nu, beta = 0)
%
% Each step picks the grid path best correlated with the residual, then
% refits all picked gains by least squares. Stops at Pmax paths or when the
% residual energy falls to 1.5x the noise energy of the observation.
nObs  = numel(yObs);
cn    = sqrt(sum(abs(dict.R).^2, 1));         % atom norms
res   = yObs;
sel   = zeros(1, 0);
g     = zeros(0, 1);
for it = 1:Pmax
    [~, j] = max(abs(dict.R' * res) ./ cn.');
    if any(sel == j), break; end
    sel = [sel, j];                           %#ok<AGROW>
    g   = dict.R(:, sel) \ yObs;
    res = yObs - dict.R(:, sel) * g;
    if sum(abs(res).^2) < 1.5 * N0 * nObs, break; end
end
est.h    = g;
est.tau  = dict.tau(sel);
est.nu   = dict.nu(sel);
est.beta = zeros(numel(sel), 1);
end
