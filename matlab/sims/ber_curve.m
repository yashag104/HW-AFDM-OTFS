function res = ber_curve(p, wfName, snrList, opt)
% BER_CURVE  Monte-Carlo BER of one waveform over a list of SNRs.
%   p       : parameters from sys_params
%   wfName  : 'AFDM' | 'OTFS-Zak' | 'OTFS-ISFFT' | 'OTFS-PS' | 'OFDM' | 'DFT-s-OFDM'
%   snrList : Es/N0 values [dB] (per data symbol)
%   opt     : options (missing fields take the defaults below)
%     det       'mp-top'  MP, S largest taps per row
%               'mp-path' MP, w taps per path per row (structured selection)
%               'lmmse'   LMMSE on the full channel (reference)
%               'fde'     one-tap frequency-domain equalizer, the standard
%                         OFDM / DFT-s-OFDM receiver (those two only)
%     S         taps per row for 'mp-top'                      (16)
%     w         taps per path for 'mp-path'                    (5)
%     csi       'genie' (true channel) or 'est' (pilot + OMP)  ('genie')
%     pilots    reserve pilot/guard positions (forced on for 'est') (false)
%     fxc       [] float, or fixed-point config for mod/demod  ([])
%     agc       scale the receive frame to unit power before quantizing (true)
%     resid     MP adds each row's dropped-tap energy to its noise variance,
%               i.e. models the interference of the dropped taps (true)
%               Reason: the Gaussian approximation otherwise counts only
%               the kept taps, underestimates the variance and becomes
%               overconfident when N0 < dropped energy (BER can then rise
%               with SNR). Measured in sims/study_resid.m.
%     etaData   MP convergence indicator counts data symbols only (true)
%               Reason: eta is defined over UNKNOWN symbols (Raviteja et
%               al.); counting known pilot/guard positions caps eta below
%               1 so the eta = 1 stop can never fire. Same BER, fewer
%               iterations (results/fixcheck.log).
%     minErrs   stop a point after this many bit errors ...    (100)
%     minFrames ... but never before this many frames          (200)
%     maxFrames hard limit on frames per point                 (2000)
%     seed      base seed; point i uses seed + i, so every configuration
%               sees the same frames (paired comparison)       (1)
%   res     : struct of vectors over snrList: ber, lo, hi (95 % CI), errs,
%             bits, frames, iters (mean MP iterations), kept (mean energy
%             held by the kept taps), satTx / satRx (share of Tx / Rx samples
%             whose real or imaginary part reaches the +/-4 data range),
%             badFrames (frames with at least one bit error: shows whether
%             errors come from a few failed frames or a steady rate), and
%             dataFrac (data share of the frame)
opt = fill_defaults(opt);
if strcmp(opt.csi, 'est'), opt.pilots = true; end
% A boosted pilot (amplitude sqrt(reserved positions), up to ~10) would
% saturate the +/-4 fixed-point input format, so fixed point runs without pilots.
assert(isempty(opt.fxc) || ~opt.pilots, 'ber_curve: fixed point is run without pilots.');
% One OFDM symbol per frame cannot resolve Doppler of more than +/-2 bins from
% comb pilots (shifts differing by the comb spacing look identical), so OFDM
% is only a genie-CSI baseline here. DFT-s-OFDM estimates on the same
% subcarriers, so the same holds for it.
ofdmLike = any(strcmp(wfName, {'OFDM', 'DFT-s-OFDM'}));
assert(~(ofdmLike && strcmp(opt.csi, 'est')), ...
       'ber_curve: OFDM and DFT-s-OFDM are evaluated with genie CSI only.');
assert(~strcmp(opt.det, 'fde') || (ofdmLike && ~opt.pilots), ...
       'ber_curve: fde is the OFDM / DFT-s-OFDM receiver and runs without pilots.');

wf = waveform(wfName, p);
[const, bits] = qam_table(p.Q);
m = log2(p.Q);
N = p.N;
if opt.pilots
    lay = pilot_layout(wfName, p);
else
    lay = struct('xp', zeros(N, 1), 'dataIdx', (1:N).', 'obsIdx', []);
end
if strcmp(opt.csi, 'est')
    dict = build_dictionary(wf, p, lay);
end
isData = false(N, 1);  isData(lay.dataIdx) = true;

nS  = numel(snrList);
res = struct('ber', zeros(1, nS), 'lo', zeros(1, nS), 'hi', zeros(1, nS), ...
             'errs', zeros(1, nS), 'bits', zeros(1, nS), 'frames', zeros(1, nS), ...
             'iters', zeros(1, nS), 'kept', zeros(1, nS), ...
             'satTx', zeros(1, nS), 'satRx', zeros(1, nS), 'badFrames', zeros(1, nS), ...
             'dataFrac', numel(lay.dataIdx) / N);
lim = 4;                                          % |value| limit of the data format (3 integer bits)
for i = 1:nS
    rng(opt.seed + i);
    N0 = 10^(-snrList(i) / 10);
    nErr = 0;  nBit = 0;  f = 0;  itSum = 0;  keptSum = 0;  satT = 0;  satR = 0;  nBad = 0;
    while f < opt.maxFrames && (nErr < opt.minErrs || f < opt.minFrames)
        f  = f + 1;
        tx = randi(p.Q, N, 1);
        x  = const(tx);
        x(~isData) = 0;
        x  = x + lay.xp;
        ch = gen_channel(p);
        s  = wf.mod(x, opt.fxc);
        r  = channel_matrix(ch, p, wf.pre, 0) * s;
        r  = r + sqrt(N0 / 2) * (randn(N, 1) + 1j * randn(N, 1));

        % CFO correction (fde only): an OFDM / DFT-s-OFDM receiver removes the
        % carrier offset before its FFT, or the one-tap equalizer fails outright
        % once the Doppler exceeds a subcarrier (LEO-Ka: 9.3 kHz vs 7.5 kHz).
        % A CP / reference-signal estimator converges to the power-weighted
        % mean Doppler; genie value, as the CSI is genie. MP and LMMSE need no
        % correction: the offset is part of the channel they are given.
        cfo = ones(N, 1);
        if strcmp(opt.det, 'fde')
            nuc = sum(abs(ch.h).^2 .* ch.nu) / sum(abs(ch.h).^2);
            cfo = exp(-1j * 2 * pi * nuc * p.Ts * (0:N - 1).');
            r   = cfo .* r;
        end

        % Gain control: the receiver sees g*r, so channel and noise scale too.
        g = 1;
        if ~isempty(opt.fxc) && opt.agc
            g = 1 / sqrt(mean(abs(r).^2));
        end
        satT = satT + sum(abs(real(s)) >= lim | abs(imag(s)) >= lim);
        satR = satR + sum(abs(real(g * r)) >= lim | abs(imag(g * r)) >= lim);
        y   = wf.demod(g * r, opt.fxc);
        N0g = g^2 * N0;

        % Channel the detector uses: true (genie) or estimated from the pilot.
        if strcmp(opt.csi, 'est')
            chD = omp_estimate(y(lay.obsIdx), dict, N0g, p.Pmax);
        else
            chD = ch;
            chD.h = g * ch.h;
        end
        H = wf.DemM * (cfo .* channel_matrix(chD, p, wf.pre, 0)) * wf.ModM;   % = eff_channel when cfo = 1
        y = y - H * lay.xp;                      % remove the (known) pilot
        H(:, ~isData) = 0;                        % pilot/guard positions carry no data

        etaMask = true(N, 1);
        if opt.etaData, etaMask = isData; end
        switch opt.det
            case 'lmmse'
                xd  = lmmse_detector(y, H(:, isData), N0g, const);
                it  = 0;  k = 1;
            case 'fde'
                xd  = fde_detector(y, H, N0g, const, strcmp(wfName, 'DFT-s-OFDM'));
                it  = 0;  k = 1;
            case 'mp-top'
                [idx, val, k, dr] = sparsify_rows(H, opt.S);
                n0 = N0g;
                if opt.resid, n0 = N0g + dr; end
                [xa, it] = mp_detector(y, idx, val, n0, const, p.mp, etaMask);
                xd = xa(isData);
            case 'mp-path'
                Hp = cell(1, numel(chD.h));
                for q = 1:numel(chD.h)
                    one = struct('h', chD.h(q), 'tau', chD.tau(q), 'nu', chD.nu(q), 'beta', chD.beta(q));
                    Hp{q} = eff_channel(wf, one, p);
                    Hp{q}(:, ~isData) = 0;
                end
                [idx, val, k, dr] = sparsify_paths(Hp, H, opt.w);
                n0 = N0g;
                if opt.resid, n0 = N0g + dr; end
                [xa, it] = mp_detector(y, idx, val, n0, const, p.mp, etaMask);
                xd = xa(isData);
            otherwise
                error('ber_curve:det', 'Unknown detector "%s".', opt.det);
        end

        td      = tx(isData);
        e       = sum(bits(td, :) ~= bits(xd, :), 'all');
        nErr    = nErr + e;
        nBad    = nBad + (e > 0);
        nBit    = nBit + numel(td) * m;
        itSum   = itSum + it;
        keptSum = keptSum + k;
    end
    res.errs(i)   = nErr;
    res.bits(i)   = nBit;
    res.frames(i) = f;
    res.ber(i)    = nErr / nBit;
    [res.lo(i), res.hi(i)] = ber_ci(nErr, nBit);
    res.iters(i)  = itSum / f;
    res.kept(i)   = keptSum / f;
    res.satTx(i)  = satT / (f * N);
    res.satRx(i)  = satR / (f * N);
    res.badFrames(i) = nBad;
end
end

function opt = fill_defaults(opt)
% FILL_DEFAULTS  Missing option fields take their default values.
def = struct('det', 'mp-top', 'S', 16, 'w', 5, 'csi', 'genie', 'pilots', false, ...
             'fxc', [], 'agc', true, 'resid', true, 'etaData', true, 'minErrs', 100, 'minFrames', 200, ...
             'maxFrames', 2000, 'seed', 1);
names = fieldnames(def);
for i = 1:numel(names)
    if ~isfield(opt, names{i})
        opt.(names{i}) = def.(names{i});
    end
end
end
