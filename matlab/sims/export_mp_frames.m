function export_mp_frames(scen, wfName, snrdB, S, Wd, nFrames)
% EXPORT_MP_FRAMES  Frames for the HLS MP-detector testbench.
%   scen    : scenario, e.g. 'LEO-Ka'
%   wfName  : 'AFDM' | 'OTFS-Zak'
%   snrdB   : Es/N0 [dB]
%   S       : taps per row kept for the detector
%   Wd      : data word length of the fixed-point transforms (sets y)
%   nFrames : number of frames
%
% The received frame goes through the fixed-point demodulator (the same
% bit-true model as the HLS transform), so y is already on the data grid.
% File hls/generated/mp/<scen>_<wf>_S<S>_<snr>dB.txt, per frame:
%   line 1        : N0
%   next N lines  : y_re y_im tx xfloat  idx_1 re_1 im_1 ... idx_S re_S im_S
% tx and xfloat are 0-based symbol indices; xfloat is the floating-point
% MP decision on the same frame; idx is 0-based.
p      = sys_params(scen);
wf     = waveform(wfName, p);
fxc    = fx_config(Wd, 16, 16);
const  = qam_table(p.Q);
N0     = 10^(-snrdB / 10);
outDir = fullfile(fileparts(mfilename('fullpath')), '..', '..', 'hls', 'generated', 'mp');
if ~exist(outDir, 'dir'), mkdir(outDir); end
name   = sprintf('%s_%s_S%d_%ddB.txt', strrep(scen, '-', ''), strrep(wfName, '-', ''), S, snrdB);

rng(500);
f = fopen(fullfile(outDir, name), 'w');
for fr = 1:nFrames
    tx = randi(p.Q, p.N, 1);
    ch = gen_channel(p);
    r  = channel_matrix(ch, p, wf.pre, 0) * wf.mod(const(tx), fxc);
    r  = r + sqrt(N0 / 2) * (randn(p.N, 1) + 1j * randn(p.N, 1));
    y  = wf.demod(r, fxc);
    [idx, val] = sparsify_rows(eff_channel(wf, ch, p), S);
    xf = mp_detector(y, idx, val, N0, const, p.mp);

    fprintf(f, '%.17g\n', N0);
    for a = 1:p.N
        fprintf(f, '%.17g %.17g %d %d', real(y(a)), imag(y(a)), tx(a) - 1, xf(a) - 1);
        fprintf(f, ' %d %.17g %.17g', [idx(a, :) - 1; real(val(a, :)); imag(val(a, :))]);
        fprintf(f, '\n');
    end
end
fclose(f);
fprintf('Exported %d frames to %s\n', nFrames, fullfile(outDir, name));
end
