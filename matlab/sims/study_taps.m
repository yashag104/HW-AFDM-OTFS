function study_taps(scen)
% STUDY_TAPS  BER against detector width at 18 dB, for both tap-selection rules.
%   mp-top  : S = 4 .. 32 largest taps per row
%   mp-path : w = 1 .. 5 taps per path per row (S = P * w)
% S (or P * w) is the width of the MP datapath, i.e. its hardware cost.
%   scen : 'V2X' | 'LEO-S' | 'LEO-Ka'
% Output: results/taps_<scen>.mat
p      = sys_params(scen);
names  = {'AFDM', 'OTFS-Zak', 'OTFS-PS'};
Slist  = [4 8 16 32];
wlist  = [1 3 5];
snrdB  = 18;
base   = struct('minErrs', 100, 'minFrames', 300, 'maxFrames', 3000, 'seed', 20);
top  = cell(numel(names), numel(Slist));
path = cell(numel(names), numel(wlist));
for n = 1:numel(names)
    for i = 1:numel(Slist)
        opt = base;  opt.det = 'mp-top';  opt.S = Slist(i);
        top{n, i} = ber_curve(p, names{n}, snrdB, opt);
    end
    for i = 1:numel(wlist)
        opt = base;  opt.det = 'mp-path';  opt.w = wlist(i);
        path{n, i} = ber_curve(p, names{n}, snrdB, opt);
    end
    fprintf('%-7s %-9s top S=%s: %s | path w=%s: %s\n', scen, names{n}, mat2str(Slist), ...
            sprintf('%.1e ', cellfun(@(r) r.ber, top(n, :))), mat2str(wlist), ...
            sprintf('%.1e ', cellfun(@(r) r.ber, path(n, :))));
end
nPaths = numel(tdl_profile(p.profile).delay);
save(fullfile(results_dir(), ['taps_' strrep(scen, '-', '') '.mat']), 'scen', 'names', 'Slist', ...
     'wlist', 'snrdB', 'top', 'path', 'nPaths', 'base', 'p');
end
