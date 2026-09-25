% TEST_TRANSFORMS  Self-checks of the transform and channel models.
% Run from the matlab/ folder:  setup_paths; test_transforms
clear; rng(1);
setup_paths;
p     = sys_params('LEO-Ka');
names = {'AFDM', 'OTFS-Zak', 'OTFS-ISFFT'};
tol   = 1e-9;
x     = (randn(p.N, 1) + 1j * randn(p.N, 1)) / sqrt(2);

% 1) Every modulator is unitary and the demodulator inverts it.
for i = 1:numel(names)
    wf = waveform(names{i}, p);
    s  = wf.mod(x, []);
    assert(abs(norm(s) - norm(x)) < tol, '%s: modulator not unitary', names{i});
    assert(norm(wf.demod(s, []) - x) < tol, '%s: demod(mod(x)) ~= x', names{i});
end
fprintf('PASS 1: all modulators unitary, demodulators invert them\n');

% 2) With rectangular pulses, ISFFT + Heisenberg equals the inverse Zak transform.
assert(norm(otfs_mod_zak(x, p, []) - otfs_mod_isfft(x, p, [])) < tol);
assert(norm(otfs_demod_zak(x, p, []) - otfs_demod_sfft(x, p, [])) < tol);
fprintf('PASS 2: OTFS two-step (ISFFT/SFFT) == Zak form\n');

% 3) On-grid channel (integer delay and Doppler, no Doppler rate):
%    each path gives exactly ONE tap per row of the effective channel.
ch.h    = [1; 0.7; 0.5] .* exp(1j * [0.3; 1.1; 2.0]);
ch.l    = [0; 2; 5];
alpha   = [0; 1; -2];                          % Doppler in bins of 1/T
ch.nu   = alpha / p.T;
ch.beta = zeros(3, 1);
for i = 1:numel(names)
    H     = eff_channel(waveform(names{i}, p), ch, p);
    nnzRw = sum(abs(H) > 1e-6, 2);
    assert(all(nnzRw == 3), '%s: expected 3 taps per row', names{i});
end
% AFDM tap positions: column = row + loc_p, loc_p = 2 N c1 l_p - alpha_p (mod N).
% (Bemani et al. write +alpha because their Doppler phase is exp(-j 2 pi f n / N);
%  apply_channel uses exp(+j 2 pi nu t), which flips the sign.)
H     = eff_channel(waveform('AFDM', p), ch, p);
loc   = sort(mod(2 * p.N * p.c1 * ch.l - alpha, p.N));
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
% With the c1 of sys_params (2*N*c1 integer, N even) the CPP is a plain CP.
scen = {'V2X', 'LEO-S', 'LEO-Ka'};
for i = 1:numel(scen)
    assert(max(abs(afdm_prefix(sys_params(scen{i})) - 1)) < tol);
end
fprintf('PASS 4: CPP formula verified; CPP == plain CP for all scenarios\n');

% 5) The channel matrix equals the sample-by-sample channel, including
%    Doppler rate, a start-time offset and a non-trivial prefix phase.
chR      = gen_channel(p);
chR.beta = 5e4 * ones(size(chR.h));            % exaggerated Doppler rate
preR     = exp(1j * 2 * pi * rand(p.Ncp, 1));
t0       = 3.7e-3;
Hc       = channel_matrix(chR, p, preR, t0);
assert(norm(Hc * x - apply_channel(x, preR, chR, p, t0)) < tol);
fprintf('PASS 5: channel_matrix == apply_channel\n');

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
