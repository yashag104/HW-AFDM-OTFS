function p = sys_params(scenario, varargin)
% SYS_PARAMS  Frame numerology and mobility scenario, shared by every script.
%   scenario : 'V2X', 'LEO-S' or 'LEO-Ka'
%   varargin : optional name-value overrides of any base setting, e.g.
%              sys_params('LEO-Ka', 'B', 3.84e6, 'elev', 90, 'profile', 'NTN-TDL-A')
%              Derived values (Ts, T, Doppler, c1, c2, Ncp) are computed AFTER overrides.
%   p        : parameter struct (all units SI: Hz, s, m)
%
% Both waveforms use the SAME bandwidth B, frame length N and prefix Ncp,
% so their delay resolution (1/B) and Doppler resolution (1/T) are identical.

% ---- Frame numerology (common to all waveforms) ----
p.N   = 256;            % samples = symbols per frame
p.M   = 16;             % OTFS delay bins  (samples per OTFS symbol)
p.K   = 16;             % OTFS Doppler bins (OTFS symbols per frame), M*K = N
p.B   = 1.92e6;         % bandwidth = sample rate [Hz]
p.Q   = 4;              % QAM order (4 = QPSK, 16 = 16-QAM)
p.xi  = 1;              % AFDM guard width for fractional Doppler
p.c2  = NaN;            % AFDM second chirp; NaN = default 1/(2*N*pi), 0 = no pre-chirp

% ---- Channel model ----
p.fracDelay = true;     % fractional delays through a raised-cosine pulse
p.rcAlpha   = 0.5;      % roll-off of the raised-cosine (Tx * Rx) pulse
p.Kh        = 6;        % pulse truncated to +/- Kh samples around each delay

% ---- Pilots and channel estimation ----
p.Lg   = 3;             % delay span [samples] the pilot guard is sized for
p.Pmax = 8;             % maximum paths the estimator extracts

% ---- MP detector (same datapath for every waveform) ----
% Chosen with sims/mp_config_study.m: with best-eta decisions 8 iterations
% reach the BER floor in every regime; damping 0.7 + stopping needs the
% fewest iterations on average.
p.mp.iter  = 10;        % maximum iterations (bounds the worst-case latency)
p.mp.damp  = 0.7;       % damping factor
p.mp.stop  = true;      % convergence-based stopping (keeps best-eta decision)
p.mp.gamma = 0.01;      % symbol converged if max probability >= 1 - gamma (swept in mp_config_study)
p.mp.eps   = 0.2;       % stop if eta falls this far below its best value (swept in mp_config_study)

% ---- Mobility scenario (base values) ----
p.name = scenario;
switch scenario
    case 'V2X'
        p.fc      = 5.9e9;           % ITS band carrier [Hz]
        p.profile = 'V2X';           % tap profile (see tdl_profile.m)
        p.DS      = 1;               % V2X profile delays are already in seconds
        p.v_rel   = 2 * 250 / 3.6;   % two cars at 250 km/h, oncoming [m/s]
        p.d_min   = 10;              % lateral distance when passing [m]
    case {'LEO-S', 'LEO-Ka'}
        if strcmp(scenario, 'LEO-S')
            p.fc = 2.0e9;            % S-band [Hz]
        else
            p.fc = 20e9;             % Ka-band downlink [Hz]
        end
        p.profile = 'NTN-TDL-C';     % LOS profile, 3GPP TR 38.811
        p.DS      = 300e-9;          % ASSUMED delay spread [s]; swept in sims/study_profiles.m
        p.h       = 600e3;           % orbit altitude [m]
        p.elev    = 50;              % elevation angle [deg]
        p.v_ue    = 500 / 3.6;       % UE speed, high-speed train [m/s]
        p.Tupd    = 20e-3;           % ASSUMED Doppler pre-compensation interval [s]; swept in study_doppler_drift.m
    otherwise
        error('sys_params:scenario', 'Unknown scenario "%s".', scenario);
end

% ---- Overrides ----
for i = 1:2:numel(varargin)
    assert(isfield(p, varargin{i}), 'sys_params: unknown field "%s".', varargin{i});
    p.(varargin{i}) = varargin{i + 1};
end
assert(p.M * p.K == p.N, 'sys_params: M*K must equal N.');

% ---- Derived values ----
c    = 299792458;       % speed of light [m/s]
p.Ts = 1 / p.B;         % sample period [s]
p.T  = p.N * p.Ts;      % frame duration [s]

if strcmp(scenario, 'V2X')
    p.nu_path_max   = p.v_rel * p.fc / c;                   % per-path Doppler spread [Hz]
    p.nu_common_max = 0;                                    % no common Doppler
    p.beta          = p.v_rel^2 * p.fc / (c * p.d_min);     % worst-case Doppler rate at pass [Hz/s]
else
    [~, beta_sat]   = leo_doppler(p.fc, p.h, p.elev);
    p.nu_path_max   = p.v_ue * p.fc / c;                    % UE-motion Doppler spread [Hz]
    p.nu_common_max = abs(beta_sat) * p.Tupd;               % residual satellite Doppler after pre-comp [Hz]
    p.beta          = beta_sat;                             % satellite Doppler rate [Hz/s]
end

% AFDM chirps (Bemani et al., TWC 2023)
p.alpha_max = ceil((p.nu_path_max + p.nu_common_max) * p.T);   % max normalized Doppler (integer)
p.c1 = (2 * (p.alpha_max + p.xi) + 1) / (2 * p.N);
if isnan(p.c2)
    p.c2 = 1 / (2 * p.N * pi);       % irrational and < 1/(2N)
end

% Prefix: longest path delay plus the pulse tail, at least 16 samples.
prof      = tdl_profile(p.profile);
maxDelay  = max(prof.delay) * p.DS / p.Ts;                  % [samples]
p.Ncp     = max(16, ceil(maxDelay) + p.Kh * p.fracDelay);
end
