function p = sys_params(scenario)
% SYS_PARAMS  Frame numerology and mobility scenario, shared by every script.
%   scenario : 'V2X', 'LEO-S' or 'LEO-Ka'
%   p        : parameter struct (all units SI: Hz, s, m)
%
% Both waveforms use the SAME bandwidth B, frame length N and prefix Ncp,
% so their delay resolution (1/B) and Doppler resolution (1/T) are identical.

% ---- Frame numerology (common to AFDM and OTFS) ----
p.N   = 256;            % samples = data symbols per frame
p.M   = 16;             % OTFS delay bins  (samples per OTFS symbol)
p.K   = 16;             % OTFS Doppler bins (OTFS symbols per frame), M*K = N
p.B   = 1.92e6;         % bandwidth = sample rate [Hz]
p.Ts  = 1 / p.B;        % sample period [s]
p.T   = p.N * p.Ts;     % frame duration [s] (133.3 us -> Doppler bin 7.5 kHz)
p.Ncp = 16;             % one prefix per frame (CPP for AFDM, CP for OTFS)
p.Q   = 4;              % QAM order (4 = QPSK, 16 = 16-QAM)
p.xi  = 1;              % AFDM guard width for fractional Doppler

% ---- MP detector (same datapath for both waveforms) ----
% Chosen with sims/mp_config_study.m (18 dB, S = 16): with best-eta decisions,
% 8 iterations reach the BER floor in every regime; damping 0.7 + stopping
% needs the fewest iterations on average (1.3 - 6.2).
p.mp.iter  = 10;        % maximum iterations (bounds the worst-case latency)
p.mp.damp  = 0.7;       % damping factor
p.mp.stop  = true;      % convergence-based stopping (keeps best-eta decision)
p.mp.gamma = 0.01;      % ASSUMED: symbol converged if max probability >= 1 - gamma
p.mp.eps   = 0.2;       % ASSUMED: stop if eta falls this far below its best value

% ---- Physical constants ----
c = 299792458;          % speed of light [m/s]

% ---- Mobility scenario ----
p.name = scenario;
switch scenario
    case 'V2X'
        p.fc      = 5.9e9;           % ITS band carrier [Hz]
        p.profile = 'V2X';           % tap profile (see tdl_profile.m)
        p.DS      = 1;               % V2X profile delays are already in seconds
        v_rel     = 2 * 250 / 3.6;   % two cars at 250 km/h, oncoming [m/s]
        d_min     = 10;              % lateral distance when passing [m]
        p.nu_path_max   = v_rel * p.fc / c;              % per-path Doppler spread [Hz]
        p.nu_common_max = 0;                             % no common Doppler
        p.beta          = v_rel^2 * p.fc / (c * d_min);  % worst-case Doppler rate at pass [Hz/s]

    case {'LEO-S', 'LEO-Ka'}
        if strcmp(scenario, 'LEO-S')
            p.fc = 2.0e9;            % S-band [Hz]
        else
            p.fc = 20e9;             % Ka-band downlink [Hz]
        end
        p.profile = 'NTN-TDL-C';     % LOS profile, 3GPP TR 38.811
        p.DS      = 300e-9;          % ASSUMED delay spread [s]; confirm from TR 38.811 Sec. 6.7.2
        p.h       = 600e3;           % orbit altitude [m]
        p.elev    = 50;              % elevation angle [deg]
        p.v_ue    = 500 / 3.6;       % UE speed, high-speed train [m/s]
        p.Tupd    = 20e-3;           % ASSUMED interval between Doppler pre-compensation updates [s]
        [~, beta_sat] = leo_doppler(p.fc, p.h, p.elev);
        p.nu_path_max   = p.v_ue * p.fc / c;             % UE-motion Doppler spread [Hz]
        p.nu_common_max = abs(beta_sat) * p.Tupd;        % residual satellite Doppler after pre-comp [Hz]
        p.beta          = beta_sat;                      % satellite Doppler rate [Hz/s]

    otherwise
        error('sys_params:scenario', 'Unknown scenario "%s".', scenario);
end

% ---- Derived AFDM chirp parameters (Bemani et al., TWC 2023) ----
p.alpha_max = ceil((p.nu_path_max + p.nu_common_max) * p.T);   % max normalized Doppler (integer)
p.c1 = (2 * (p.alpha_max + p.xi) + 1) / (2 * p.N);
p.c2 = 1 / (2 * p.N * pi);           % irrational and < 1/(2N)
end
