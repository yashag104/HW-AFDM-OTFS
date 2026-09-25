% DOPPLER_STUDY  How large are Doppler and Doppler rate in each regime, and
% do they matter inside one frame or only across frames?
% Run from the matlab/ folder:  setup_paths; doppler_study
clear;
setup_paths;
c = 299792458;

fprintf('\n=== Scenario summary (frame T = N/B) ===\n');
fprintf('%-7s %8s %10s %10s %6s %10s %12s %14s\n', 'scen', 'fc[GHz]', 'nu_path', ...
        'nu_comm', 'a_max', '2N*c1', 'beta[Hz/s]', 'rate-phase[rad]');
scen = {'V2X', 'LEO-S', 'LEO-Ka'};
for i = 1:numel(scen)
    p = sys_params(scen{i});
    % Extra phase from the Doppler rate at the end of one frame: pi * beta * T^2
    ratePhase = pi * abs(p.beta) * p.T^2;
    fprintf('%-7s %8.2f %10.0f %10.0f %6d %10.0f %12.0f %14.2e\n', p.name, p.fc / 1e9, ...
            p.nu_path_max, p.nu_common_max, p.alpha_max, 2 * p.N * p.c1, p.beta, ratePhase);
end

fprintf('\n=== LEO satellite Doppler vs elevation (600 km) ===\n');
fprintf('%6s %12s %12s %12s %12s %16s\n', 'elev', 'nu_S[kHz]', 'beta_S', ...
        'nu_Ka[kHz]', 'beta_Ka', 'Ka drift/Tupd[Hz]');
p = sys_params('LEO-Ka');
for elev = [10 30 50 70 90]
    [nuS, bS]   = leo_doppler(2e9,  p.h, elev);
    [nuKa, bKa] = leo_doppler(20e9, p.h, elev);
    fprintf('%6d %12.2f %12.1f %12.2f %12.1f %16.1f\n', elev, nuS / 1e3, bS, ...
            nuKa / 1e3, bKa, abs(bKa) * p.Tupd);
end

fprintf('\nDoppler bin 1/T = %.0f Hz.  Frame T = %.1f us.\n', 1 / p.T, p.T * 1e6);
