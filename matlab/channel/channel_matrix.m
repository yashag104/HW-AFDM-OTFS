function Hc = channel_matrix(ch, p, pre, t0)
% CHANNEL_MATRIX  Time-domain channel as an N x N matrix, r = Hc * s.
%   ch  : channel from gen_channel (fields h, tau, nu, beta)
%   p   : parameters from sys_params
%   pre : Ncp x 1 prefix phase of the waveform
%   t0  : absolute start time of the frame [s]
%   Hc  : N x N sparse matrix; equal to apply_channel(s, pre, ch, p, t0) for every s
%
% Row n (0-based, after prefix removal) is stream sample i = n + Ncp. For each
% pulse shift k it reads stream sample i - k: a frame sample if >= Ncp, a
% prefix sample (times its phase) if in [0, Ncp), nothing if outside the frame.
N   = p.N;
Ncp = p.Ncp;
n   = (0:N - 1).';
i   = n + Ncp;                                % stream index of each row
t   = t0 + i * p.Ts;                          % receive time of each row

rows = [];  cols = [];  vals = [];
for k = 1:numel(ch.h)
    phase = ch.h(k) * exp(1j * 2 * pi * (ch.nu(k) * t + 0.5 * ch.beta(k) * t.^2));
    [shift, w] = path_shifts(ch.tau(k), p);
    for j = 1:numel(shift)
        src  = i - shift(j);                  % stream index read by each row
        gain = w(j) * phase;
        inPre = src >= 0 & src < Ncp;
        gain(inPre) = gain(inPre) .* pre(src(inPre) + 1);
        ok   = src >= 0 & src < N + Ncp;
        col  = mod(src - Ncp, N) + 1;         % prefix sample m maps to s[N - Ncp + m]
        rows = [rows; n(ok) + 1];             %#ok<AGROW>
        cols = [cols; col(ok)];               %#ok<AGROW>
        vals = [vals; gain(ok)];              %#ok<AGROW>
    end
end
Hc = sparse(rows, cols, vals, N, N);          % duplicates (same column) are summed
end
