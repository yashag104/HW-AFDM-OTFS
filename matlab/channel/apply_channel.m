function r = apply_channel(s, pre, ch, p, t0)
% APPLY_CHANNEL  Pass one frame through the time-varying multipath channel,
% sample by sample (reference implementation; channel_matrix is the fast one).
%   s   : N x 1 transmit frame (without prefix)
%   pre : Ncp x 1 prefix phase (ones for CP, chirp phase for AFDM CPP)
%   ch  : channel from gen_channel
%   p   : parameters from sys_params
%   t0  : absolute start time of the frame [s] (0 for a single frame)
%   r   : N x 1 received frame after prefix removal (noise-free)
%
% r(t) = sum_p h_p exp(j 2 pi (nu_p t + beta_p t^2 / 2)) sum_k g(k - tau_p) u(t - k)
% with u the frame plus prefix and g the raised-cosine pulse. Samples from the
% previous or next frame are not modelled (zero).

N   = p.N;
Ncp = p.Ncp;
L   = N + Ncp;

u = [s(N - Ncp + 1:N) .* pre; s];         % frame with prefix
i = (0:L - 1).';                          % stream index
t = t0 + i * p.Ts;                        % receive time of each sample

r = zeros(N, 1);
for k = 1:numel(ch.h)
    [shift, w] = path_shifts(ch.tau(k), p);
    v = zeros(L, 1);
    for j = 1:numel(shift)
        src = i - shift(j);               % stream sample that arrives at i
        ok  = src >= 0 & src < L;
        v(ok) = v(ok) + w(j) * u(src(ok) + 1);
    end
    v = ch.h(k) * exp(1j * 2 * pi * (ch.nu(k) * t + 0.5 * ch.beta(k) * t.^2)) .* v;
    r = r + v(Ncp + 1:end);               % drop the prefix
end
end
