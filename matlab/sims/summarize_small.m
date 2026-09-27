% SUMMARIZE_SMALL  Tables of the short sensitivity studies -> results/summary_small.txt
% Run from the matlab/ folder after study_small('afdm'|'drift'|'profiles'|'numerology'|'qam16').
setup_paths;
f = fopen(fullfile(results_dir(), 'summary_small.txt'), 'w');
out1 = @(varargin) fprintf(f, varargin{:});

file = @(w) fullfile(results_dir(), ['small_' w '.mat']);

if exist(file('afdm'), 'file')
    load(file('afdm'), 'out');
    out1('== AFDM guard xi and second chirp c2 (BER at 18 dB, fractional delays, genie CSI)\n');
    for s = 1:numel(out.scen)
        out1('%s\n  %-4s %-22s %-22s\n', out.scen{s}, 'xi', 'c2 default: MP / LMMSE', 'c2 = 0: MP / LMMSE');
        for i = 1:numel(out.xis)
            out1('  %-4d %9.2e / %-9.2e   %9.2e / %-9.2e\n', out.xis(i), out.ber(s, i, 1, 1), ...
                 out.ber(s, i, 1, 2), out.ber(s, i, 2, 1), out.ber(s, i, 2, 2));
        end
    end
    out1('\n');
end

if exist(file('drift'), 'file')
    load(file('drift'), 'out');
    out1('== Doppler pre-compensation interval (LEO-Ka, zenith, 18 dB; MP / LMMSE)\n');
    out1('  %-8s %-8s %-11s %-22s %-22s %-22s\n', 'Tupd[s]', 'a_max', 'resid[Hz]', out.cfg{:});
    for i = 1:numel(out.Tupd)
        out1('  %-8.2f %-8d %-11.0f', out.Tupd(i), out.alpha(i), out.nuRes(i));
        for k = 1:3
            out1(' %9.2e / %-9.2e ', out.ber(i, k, 1), out.ber(i, k, 2));
        end
        out1('\n');
    end
    out1('\n');
end

if exist(file('profiles'), 'file')
    load(file('profiles'), 'out');
    out1('== NTN-TDL profile x delay spread (LEO-Ka, 18 dB; MP / LMMSE)\n');
    for a = 1:numel(out.profs)
        for b = 1:numel(out.DS)
            out1('  %-10s DS %5.0f ns  lmax %5.1f  Ncp %2d |', out.profs{a}, out.DS(b) * 1e9, ...
                 out.lmax(a, b), out.Ncp(a, b));
            for n = 1:numel(out.names)
                out1('  %s %9.2e / %-9.2e', out.names{n}, out.ber(a, b, n, 1), out.ber(a, b, n, 2));
            end
            out1('\n');
        end
    end
    out1('\n');
end

if exist(file('numerology'), 'file')
    load(file('numerology'), 'out');
    out1('== Bandwidth (N = 256), BER at %s dB (MP / LMMSE)\n', mat2str(out.snr));
    for s = 1:numel(out.scen)
        for b = 1:numel(out.Bs)
            out1('  %-6s B %.2f MHz  max Doppler %.2f bins |', out.scen{s}, out.Bs(b) / 1e6, out.nuNorm(s, b));
            for n = 1:numel(out.names)
                out1('  %s MP %s LMMSE %s', out.names{n}, sprintf('%.1e ', squeeze(out.ber(s, b, n, 1, :))), ...
                     sprintf('%.1e ', squeeze(out.ber(s, b, n, 2, :))));
            end
            out1('\n');
        end
    end
    out1('\n');
end

if exist(file('qam16'), 'file')
    load(file('qam16'), 'out');
    out1('== 16-QAM, LEO-Ka, SNR %s dB\n', mat2str(out.snr));
    for n = 1:numel(out.names)
        for d = 1:2
            out1('  %-9s %-7s %s\n', out.names{n}, out.dets{d}, sprintf('%.1e ', squeeze(out.ber(n, d, :))));
        end
    end
end
fclose(f);
type(fullfile(results_dir(), 'summary_small.txt'));
