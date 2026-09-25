function ch = gen_channel(p)
% GEN_CHANNEL  Draw one random realization of the doubly dispersive channel.
%   p  : parameters from sys_params
%   ch : struct with one row per path
%          h    - complex gain (total power normalized to 1)
%          l    - integer delay [samples]
%          nu   - Doppler shift at frame start [Hz]
%          beta - Doppler rate [Hz/s]
%
% Per-path Doppler = common part + motion part:
%   common : residual satellite Doppler after pre-compensation (LEO only),
%            uniform in [-nu_common_max, +nu_common_max], same for all paths
%   motion : nu_path_max * cos(theta_p), theta_p uniform (Jakes-type spread)

prof = tdl_profile(p.profile);
P    = numel(prof.delay);

% Gains: LOS taps have fixed magnitude and random phase, others are Rayleigh.
pw   = 10 .^ (prof.powerdB / 10);
pw   = pw / sum(pw);
phi  = 2 * pi * rand(P, 1);
ray  = (randn(P, 1) + 1j * randn(P, 1)) / sqrt(2);
ch.h = sqrt(pw) .* ray;
ch.h(prof.isLOS) = sqrt(pw(prof.isLOS)) .* exp(1j * phi(prof.isLOS));

% Integer delays on the sample grid.
ch.l = round(prof.delay * p.DS / p.Ts);
assert(max(ch.l) <= p.Ncp, 'gen_channel: delay spread exceeds the prefix.');

% Doppler shift and Doppler rate.
nu_common = p.nu_common_max * (2 * rand - 1);
theta     = 2 * pi * rand(P, 1);
ch.nu     = nu_common + p.nu_path_max * cos(theta);
ch.beta   = p.beta * ones(P, 1);
end
