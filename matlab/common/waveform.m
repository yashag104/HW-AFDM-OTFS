function wf = waveform(name, p)
% WAVEFORM  Bundle the modulator, demodulator and prefix of one waveform.
%   name : 'AFDM' | 'OTFS-Zak' | 'OTFS-ISFFT'
%   p    : parameters from sys_params
%   wf   : struct with
%            name  - waveform name
%            mod   - @(x, fxc) N x 1 time frame
%            demod - @(r, fxc) N x 1 detection-domain samples
%            pre   - Ncp x 1 prefix phase
%            ModM  - N x N floating-point modulator matrix,   s = ModM * x
%            DemM  - N x N floating-point demodulator matrix, y = DemM * r
switch name
    case 'AFDM'
        wf.mod   = @(x, fxc) afdm_mod(x, p, fxc);
        wf.demod = @(r, fxc) afdm_demod(r, p, fxc);
        wf.pre   = afdm_prefix(p);
    case 'OTFS-Zak'
        wf.mod   = @(x, fxc) otfs_mod_zak(x, p, fxc);
        wf.demod = @(r, fxc) otfs_demod_zak(r, p, fxc);
        wf.pre   = ones(p.Ncp, 1);
    case 'OTFS-ISFFT'
        wf.mod   = @(x, fxc) otfs_mod_isfft(x, p, fxc);
        wf.demod = @(r, fxc) otfs_demod_sfft(r, p, fxc);
        wf.pre   = ones(p.Ncp, 1);
    otherwise
        error('waveform:name', 'Unknown waveform "%s".', name);
end
wf.name = name;

% The transforms are linear: apply them to the identity once.
I       = eye(p.N);
wf.ModM = zeros(p.N);
wf.DemM = zeros(p.N);
for i = 1:p.N
    wf.ModM(:, i) = wf.mod(I(:, i), []);
    wf.DemM(:, i) = wf.demod(I(:, i), []);
end
end
