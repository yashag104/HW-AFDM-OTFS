% TEST_TRANSFORMS  Self-checks of the transforms, channel, estimator and detectors.
% Run from the matlab/ folder:  setup_paths; test_transforms
clear; rng(1);
setup_paths;
p     = sys_params('LEO-Ka');
names = {'AFDM', 'OTFS-Zak', 'OTFS-ISFFT', 'OTFS-PS', 'OFDM'};
tol   = 1e-9;
x     = (randn(p.N, 1) + 1j * randn(p.N, 1)) / sqrt(2);

% 1) Modulators: unitary ones invert exactly; pulse-shaped OTFS keeps unit
%    average energy (its window is part of the effective channel instead).
for i = 1:numel(names)
    wf = waveform(names{i}, p);
    if strcmp(names{i}, 'OTFS-PS')
        e = mean(abs(wf.ModM(:)).^2) * p.N;       % average energy per symbol
        assert(abs(e - 1) < 1e-9, 'OTFS-PS: average energy %.4f', e);
    else
        s = wf.mod(x, []);
        assert(abs(norm(s) - norm(x)) < tol, '%s: modulator not unitary', names{i});
        assert(norm(wf.demod(s, []) - x) < tol, '%s: demod(mod(x)) ~= x', names{i});
    end
end
fprintf('PASS 1: modulators unitary (OTFS-PS: unit average energy)\n');

% 2) With rectangular pulses, ISFFT + Heisenberg equals the inverse Zak transform.
assert(norm(otfs_mod_zak(x, p, []) - otfs_mod_isfft(x, p, [])) < tol);
assert(norm(otfs_demod_zak(x, p, []) - otfs_demod_sfft(x, p, [])) < tol);
% A diagonal per-symbol time pulse (as in Rou et al., IEEE SPM 2024, eq. 17)
% commutes with the FFT pair: ISFFT + pulse-shaped Heisenberg = Zak form
% followed by a real per-sample scaling, i.e. still ONE pass, not three.
X   = reshape(x, p.M, p.K);
pt  = 0.5 + rand(p.M, 1);                          % arbitrary real pulse
XTF = fft_cols(fft_cols(X, false, []).', true, []).';
S3  = pt .* fft_cols(XTF, true, []);               % three-pass, pulse-shaped
S1  = pt .* reshape(otfs_mod_zak(x, p, []), p.M, p.K);   % one pass + scaling
assert(norm(S3(:) - S1(:)) < tol, 'diagonal pulse does not collapse');
% A time-frequency window does NOT commute, so it keeps the three passes.
S3w = reshape(otfs_mod_ps(x, p, []), p.M, p.K);
assert(norm(S3w(:) - S1(:)) > 0.1);
fprintf('PASS 2: OTFS two-step (ISFFT/SFFT) == Zak form; diagonal time pulse collapses too, TF window does not\n');

% 3) On-grid channel (integer delay and Doppler, no Doppler rate):
%    each path gives exactly ONE tap per row of the effective channel.
ch.h    = [1; 0.7; 0.5] .* exp(1j * [0.3; 1.1; 2.0]);
ch.tau  = [0; 2; 5];
alpha   = [0; 1; -2];                          % Doppler in bins of 1/T
ch.nu   = alpha / p.T;
ch.beta = zeros(3, 1);
for i = 1:3
    H = eff_channel(waveform(names{i}, p), ch, p);
    assert(all(sum(abs(H) > 1e-6, 2) == 3), '%s: expected 3 taps per row', names{i});
end
% AFDM tap positions: column = row + loc_p, loc_p = 2 N c1 l_p - alpha_p (mod N).
% (Bemani et al. write +alpha because their Doppler phase is exp(-j 2 pi f n / N);
%  apply_channel uses exp(+j 2 pi nu t), which flips the sign.)
H     = eff_channel(waveform('AFDM', p), ch, p);
loc   = sort(mod(2 * p.N * p.c1 * ch.tau - alpha, p.N));
found = sort(mod(find(abs(H(1, :)) > 1e-6) - 1, p.N)).';
assert(isequal(found, loc), 'AFDM: tap positions differ from theory');
fprintf('PASS 3: on-grid channel -> exactly P taps/row, AFDM positions match theory\n');

% 4) Chirp-periodic prefix. The prefix must equal the IDAFT basis evaluated at
%    negative time, s[n] = (1/sqrt(N)) sum_m x[m] exp(j 2 pi (c1 n^2 + c2 m^2 + n m / N)).
%    Checked with a non-integer 2*N*c1, where the CPP is NOT a plain CP.
q    = p;
q.c1 = 0.013;                                   % 2*N*c1 = 6.656
pre  = afdm_prefix(q);
assert(max(abs(pre - 1)) > 0.1, 'test needs a non-trivial CPP');
s    = afdm_mod(x, q, []);
n    = (-q.Ncp:-1).';
m    = 0:q.N - 1;
ext  = exp(1j * 2 * pi * (q.c1 * n.^2 + n * m / q.N)) * (exp(1j * 2 * pi * q.c2 * m.^2).' .* x) / sqrt(q.N);
assert(norm(ext - s(q.N + n + 1) .* pre) < tol, 'AFDM CPP formula wrong');
scen = {'V2X', 'LEO-S', 'LEO-Ka'};
for i = 1:numel(scen)
    assert(max(abs(afdm_prefix(sys_params(scen{i})) - 1)) < tol);
end
fprintf('PASS 4: CPP formula verified; CPP == plain CP for all scenarios\n');

% 5) The channel matrix equals the sample-wise channel, with fractional
%    delays, Doppler rate, a start-time offset and a non-trivial prefix phase.
chR      = gen_channel(p);
chR.tau  = chR.tau + 0.37;                      % force fractional delays
chR.beta = 5e4 * ones(size(chR.h));             % exaggerated Doppler rate
preR     = exp(1j * 2 * pi * rand(p.Ncp, 1));
t0       = 3.7e-3;
Hc       = channel_matrix(chR, p, preR, t0);
assert(norm(Hc * x - apply_channel(x, preR, chR, p, t0)) < tol);
% On-grid delays reduce to pure sample shifts (pulse weights 1 and 0).
assert(abs(rc_pulse(0, p.rcAlpha) - 1) < 1e-15 && max(abs(rc_pulse([-3 -1 1 2], p.rcAlpha))) < 1e-15);
fprintf('PASS 5: channel_matrix == apply_channel (fractional delays); RC pulse on grid = shift\n');

% 6) Fixed point converges to floating point as the word length grows.
fxc = fx_config(24, 18, 18);
for i = 1:numel(names)
    wf   = waveform(names{i}, p);
    ref  = wf.mod(x, []);
    got  = wf.mod(x, fxc);
    sqnr = 10 * log10(sum(abs(ref).^2) / sum(abs(got - ref).^2));
    assert(sqnr > 80, '%s: fixed-point SQNR only %.1f dB', names{i}, sqnr);
    fprintf('        %-10s  24-bit data, 18-bit ROM : SQNR = %5.1f dB\n', names{i}, sqnr);
end
fprintf('PASS 6: fixed-point model matches floating point\n');

% 7) Estimator: noise-free pilot, channel on the dictionary grid -> the
%    estimated effective channel equals the true one. (OFDM is excluded:
%    one symbol per frame cannot resolve this Doppler from comb pilots.)
chE.h    = [1; 0.5 * exp(1j)];
chE.tau  = [0; 1.5];
chE.nu   = [0.75; -1.25] / p.T;
chE.beta = [0; 0];
for i = [1 2 4]
    wf   = waveform(names{i}, p);
    lay  = pilot_layout(names{i}, p);
    dict = build_dictionary(wf, p, lay);
    Ht   = eff_channel(wf, chE, p);
    yp   = Ht * lay.xp;                         % pilot only, no noise, no data
    est  = omp_estimate(yp(lay.obsIdx), dict, 1e-12, p.Pmax);
    err  = norm(eff_channel(wf, est, p) - Ht, 'fro') / norm(Ht, 'fro');
    assert(err < 1e-6, '%s: estimation error %.2e', names{i}, err);
    fprintf('        %-10s  data %3d / %d symbols, channel error %.1e\n', names{i}, ...
            numel(lay.dataIdx), p.N, err);
end
fprintf('PASS 7: pilot + OMP recovers an on-grid channel exactly\n');

% 8) Detectors: at very high SNR every detector recovers the data.
opt = struct('minErrs', 0, 'minFrames', 20, 'maxFrames', 20);
for det = {'lmmse', 'mp-top', 'mp-path'}
    opt.det = det{1};
    for i = [1 2 5]
        r = ber_curve(p, names{i}, 60, opt);
        assert(r.errs == 0, '%s / %s: %d errors at 60 dB', names{i}, det{1}, r.errs);
    end
end
fprintf('PASS 8: LMMSE and both MP variants error-free at 60 dB\n');
