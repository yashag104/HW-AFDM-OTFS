function mp_config_study(scen)
% MP_CONFIG_STUDY  Choose the MP detector settings, at two SNRs.
%   fixed : no stopping rule, iterations 4 .. 20 (damping 0.7)
%   stop  : stopping rule with max 20 iterations, gamma x eps grid (damping 0.7)
% Iterations set the detector latency; the stopping rule can end early.
% MP with S = 16, fractional delays, genie CSI; same frames everywhere.
%   scen : 'V2X' | 'LEO-S' | 'LEO-Ka'
% Output: results/mp_config_<scen>.mat
p      = sys_params(scen);
names  = {'AFDM', 'OTFS-Zak'};
snr    = [12 18];
iters  = [4 6 8 10 15 20];
gammas = [0.001 0.01 0.05];
epss   = [0.1 0.2 0.4];
base   = struct('S', 16, 'minErrs', 100, 'minFrames', 300, 'maxFrames', 2000, 'seed', 70);

berFixed = zeros(numel(names), numel(snr), numel(iters));
berStop  = zeros(numel(names), numel(snr), numel(gammas), numel(epss));
itStop   = zeros(size(berStop));
for n = 1:numel(names)
    q = p;  q.mp.damp = 0.7;
    q.mp.stop = false;
    for i = 1:numel(iters)
        q.mp.iter = iters(i);
        r = ber_curve(q, names{n}, snr, base);
        berFixed(n, :, i) = r.ber;
    end
    q.mp.stop = true;  q.mp.iter = 20;
    for a = 1:numel(gammas)
        for b = 1:numel(epss)
            q.mp.gamma = gammas(a);  q.mp.eps = epss(b);
            r = ber_curve(q, names{n}, snr, base);
            berStop(n, :, a, b) = r.ber;
            itStop(n, :, a, b)  = r.iters;
        end
    end
    fprintf('%-7s %-9s fixed@18dB %s\n', scen, names{n}, sprintf('%.1e ', squeeze(berFixed(n, 2, :))));
end
save(fullfile(results_dir(), ['mp_config_' strrep(scen, '-', '') '.mat']), 'scen', 'names', 'snr', ...
     'iters', 'gammas', 'epss', 'berFixed', 'berStop', 'itStop', 'base');
end
