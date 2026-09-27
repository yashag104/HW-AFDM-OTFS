function dict = build_dictionary(wf, p, lay)
% BUILD_DICTIONARY  Predicted pilot response of every candidate path.
%   wf   : waveform from waveform()
%   p    : parameters (Lg, alpha_max, xi, T, fracDelay)
%   lay  : pilot layout from pilot_layout
%   dict : struct with
%            tau, nu - candidate delay [samples] and Doppler [Hz], A x 1
%            R       - |obsIdx| x A responses on the observed samples
%
% Grid: delay 0..Lg in steps of 0.5 sample (1 if delays are integer),
% Doppler +/-(alpha_max + xi) bins in steps of 0.25 bin. The same grid and
% the same estimator are used for every waveform.
if p.fracDelay, dStep = 0.5; else, dStep = 1; end
a     = p.alpha_max + p.xi;
[tg, ng] = ndgrid(0:dStep:p.Lg, (-a:0.25:a) / p.T);
dict.tau = tg(:);
dict.nu  = ng(:);
nA  = numel(dict.tau);
sp  = wf.ModM * lay.xp;                       % transmitted pilot
dict.R = zeros(numel(lay.obsIdx), nA);
for j = 1:nA
    atom = struct('h', 1, 'tau', dict.tau(j), 'nu', dict.nu(j), 'beta', 0);
    y    = wf.DemM * (channel_matrix(atom, p, wf.pre, 0) * sp);
    dict.R(:, j) = y(lay.obsIdx);
end
end
