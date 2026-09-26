function r = apply_channel(s, pre, ch, p, t0)
% APPLY_CHANNEL  Pass one frame through the time-varying multipath channel.
%   s   : N x 1 transmit frame (without prefix)
%   pre : Ncp x 1 prefix phase (ones for CP, chirp phase for AFDM CPP)
%   ch  : channel from gen_channel
%   p   : parameters from sys_params
%   t0  : absolute start time of the frame [s] (0 for a single frame)
%   r   : N x 1 received frame after prefix removal (noise-free)
%
% r(t) = sum_p h_p exp(j 2 pi (nu_p t + beta_p t^2 / 2)) s(t - l_p Ts)
% The Doppler phase is evaluated at the receive instant t.

N   = p.N;
Ncp = p.Ncp;

u = [s(N - Ncp + 1:N) .* pre; s];         % frame with prefix, length N + Ncp
t = t0 + (0:N + Ncp - 1).' * p.Ts;        % receive time of each sample

r = zeros(N, 1);
for k = 1:numel(ch.h)
    delayed = [zeros(ch.l(k), 1); u(1:end - ch.l(k))];
    phase   = exp(1j * 2 * pi * (ch.nu(k) * t + 0.5 * ch.beta(k) * t.^2));
    v       = ch.h(k) * phase .* delayed;
    r       = r + v(Ncp + 1:end);         % drop the prefix
end
end
