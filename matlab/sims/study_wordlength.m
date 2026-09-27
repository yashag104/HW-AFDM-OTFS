function study_wordlength(scen)
% STUDY_WORDLENGTH  End-to-end BER with fixed-point modulator and demodulator,
% receive gain control on, fractional delays, genie CSI, MP with S = 16.
% Also records how often Tx and Rx samples reach the data range.
%   scen : 'V2X' | 'LEO-S' | 'LEO-Ka'
% Output: results/wordlength_<scen>.mat
p     = sys_params(scen);
names = {'AFDM', 'OTFS-Zak', 'OTFS-ISFFT', 'OTFS-PS', 'OFDM'};
Wlist = [6 8 10 12];                  % data word lengths [bits]; float is added last
Wrom  = 16;                           % twiddle / chirp / window ROM width [bits]
snr   = 0:4:24;
base  = struct('S', 16, 'minErrs', 100, 'minFrames', 200, 'maxFrames', 2000, 'seed', 50);
cfgs  = [num2cell(Wlist), {[]}];
R = cell(numel(names), numel(cfgs));
for n = 1:numel(names)
    for c = 1:numel(cfgs)
        opt = base;
        if ~isempty(cfgs{c}), opt.fxc = fx_config(cfgs{c}, Wrom, Wrom); end
        R{n, c} = ber_curve(p, names{n}, snr, opt);
        if isempty(cfgs{c}), lbl = 'float'; else, lbl = sprintf('W=%d', cfgs{c}); end
        fprintf('%-10s %-6s BER %s | satRx %.1e satTx %.1e\n', names{n}, lbl, ...
                sprintf('%.1e ', R{n, c}.ber), max(R{n, c}.satRx), max(R{n, c}.satTx));
    end
end
save(fullfile(results_dir(), ['wordlength_' strrep(scen, '-', '') '.mat']), 'scen', 'names', ...
     'Wlist', 'Wrom', 'snr', 'R', 'base', 'p');
end
