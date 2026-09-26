function res = ber_point(p, wf, snrdB, S, fxc, nFrames)
% BER_POINT  Monte-Carlo BER of one waveform at one SNR.
%   p       : parameters from sys_params (Q, mp detector settings, ...)
%   wf      : waveform from waveform()
%   snrdB   : Es/N0 per symbol [dB]
%   S       : channel taps per row given to the MP detector
%   fxc     : [] for floating point, or fixed-point config for mod/demod
%   nFrames : number of frames (fixed; no early stop, so callers can reuse the
%             same random channels for every configuration by resetting rng)
%   res     : struct with ber, errs, bits, kept (mean energy held by S taps),
%             iters (mean MP iterations used)
%
% Chain: QAM -> mod -> channel (+prefix) -> AWGN -> demod -> MP detector.
% The detector knows the true effective channel (perfect CSI), truncated to S taps.
% Random draws per frame, in order: symbols, channel, noise. They do not depend
% on the waveform, so AFDM and OTFS see identical channels for the same seed.
[const, bits] = qam_table(p.Q);
m   = log2(p.Q);
N0  = 10^(-snrdB / 10);

nErr = 0;  nBit = 0;  kept = 0;  iters = 0;
for f = 1:nFrames
    tx = randi(p.Q, p.N, 1);
    ch = gen_channel(p);
    r  = channel_matrix(ch, p, wf.pre, 0) * wf.mod(const(tx), fxc);
    r  = r + sqrt(N0 / 2) * (randn(p.N, 1) + 1j * randn(p.N, 1));
    y  = wf.demod(r, fxc);

    [idx, val, k] = sparsify_rows(eff_channel(wf, ch, p), S);
    [xhat, it] = mp_detector(y, idx, val, N0, const, p.mp);

    nErr  = nErr + sum(bits(tx, :) ~= bits(xhat, :), 'all');
    nBit  = nBit + p.N * m;
    kept  = kept + k;
    iters = iters + it;
end
res.ber   = nErr / nBit;
res.errs  = nErr;
res.bits  = nBit;
res.kept  = kept / nFrames;
res.iters = iters / nFrames;
end
