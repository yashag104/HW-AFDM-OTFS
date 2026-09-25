function Hc = channel_matrix(ch, p, pre, t0)
% CHANNEL_MATRIX  Time-domain channel as an N x N matrix, r = Hc * s.
%   ch  : channel from gen_channel
%   p   : parameters from sys_params
%   pre : Ncp x 1 prefix phase of the waveform
%   t0  : absolute start time of the frame [s]
%   Hc  : N x N matrix; identical to apply_channel(s, pre, ch, p, t0) for every s
%
% Row n (0-based, after prefix removal) of path k reads transmit sample n - l_k;
% if that index is negative it comes from the prefix: s[N + n - l_k] * pre(...).
N   = p.N;
Ncp = p.Ncp;
n   = (0:N - 1).';
t   = t0 + (n + Ncp) * p.Ts;                  % receive time of row n

Hc = zeros(N);
for k = 1:numel(ch.h)
    phase = ch.h(k) * exp(1j * 2 * pi * (ch.nu(k) * t + 0.5 * ch.beta(k) * t.^2));
    src   = n - ch.l(k);                      % transmit index being read
    wrap  = src < 0;                          % read from the prefix
    gain  = phase;
    gain(wrap) = gain(wrap) .* pre(src(wrap) + Ncp + 1);
    col   = mod(src, N) + 1;
    Hc    = Hc + sparse(n + 1, col, gain, N, N);
end
Hc = full(Hc);
end
