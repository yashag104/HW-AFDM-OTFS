function mp_config_study(scen)
% MP_CONFIG_STUDY  Choose the MP detector settings: iterations, damping, stopping.
% Iterations set the detector latency in hardware; the stopping rule adds a
% small comparator but can end early. Same frames for every configuration.
%   scen : 'V2X' | 'LEO-S' | 'LEO-Ka'
% Output: results/mp_config_<scen>.mat
setup_paths;
p       = sys_params(scen);
names   = {'AFDM', 'OTFS-Zak'};
iters   = [4 6 8 10 15 20];
damps   = [0.3 0.5 0.7];
snrdB   = 18;
S       = 16;
nFrames = 1000;

berFixed = zeros(numel(names), numel(damps), numel(iters));   % no early stop
berStop  = zeros(numel(names), numel(damps));                 % stop rule, max 20
itStop   = zeros(numel(names), numel(damps));                 % mean iterations used
for w = 1:numel(names)
    wf = waveform(names{w}, p);
    for d = 1:numel(damps)
        q = p;
        q.mp.damp = damps(d);
        q.mp.stop = false;
        for i = 1:numel(iters)
            q.mp.iter = iters(i);
            rng(400);
            berFixed(w, d, i) = ber_point(q, wf, snrdB, S, [], nFrames).ber;
        end
        q.mp.stop = true;
        q.mp.iter = 20;
        rng(400);
        r = ber_point(q, wf, snrdB, S, [], nFrames);
        berStop(w, d) = r.ber;
        itStop(w, d)  = r.iters;
        fprintf('%-7s %-9s damp %.1f | fixed %s| stop %.1e (%.1f it)\n', scen, names{w}, ...
                damps(d), sprintf('%.1e ', berFixed(w, d, :)), berStop(w, d), itStop(w, d));
    end
end

outDir = fullfile(fileparts(mfilename('fullpath')), '..', '..', 'results');
save(fullfile(outDir, ['mp_config_' strrep(scen, '-', '') '.mat']), 'scen', 'names', 'iters', ...
     'damps', 'snrdB', 'S', 'nFrames', 'berFixed', 'berStop', 'itStop');
end
