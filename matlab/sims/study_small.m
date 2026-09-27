function study_small(which)
% STUDY_SMALL  The shorter sensitivity studies (one call per study).
%   which : 'afdm'      AFDM guard xi = 0..3 and c2 = 0 vs default (hardware
%                       variant without the pre-chirp), 18 dB
%           'drift'     LEO-Ka at zenith, Doppler pre-compensation interval
%                       Tupd = 0.02 .. 2 s; AFDM with c1 fixed for 20 ms vs
%                       c1 re-designed, OTFS-Zak; 18 dB
%           'profiles'  LEO-Ka, NTN-TDL-A..D x delay spread 100/300/1000 ns, 18 dB
%           'numerology' bandwidth 0.96 / 1.92 / 3.84 MHz (N = 256), 8/16/24 dB
%           'qam16'     16-QAM, LEO-Ka, 0..28 dB
% Output: results/small_<which>.mat. All genie CSI, fractional delays.
base = struct('S', 16, 'minErrs', 100, 'minFrames', 200, 'maxFrames', 2000, 'seed', 40);
out  = struct();
switch which
    case 'afdm'
        scen = {'V2X', 'LEO-Ka'};  xis = 0:3;  c2s = [NaN 0];
        for s = 1:2
            for i = 1:numel(xis)
                for c = 1:2
                    p = sys_params(scen{s}, 'xi', xis(i), 'c2', c2s(c));
                    for d = {'mp-top', 'lmmse'}
                        opt = base;  opt.det = d{1};
                        r = ber_curve(p, 'AFDM', 18, opt);
                        out.ber(s, i, c, strcmp(d{1}, 'lmmse') + 1) = r.ber;
                        out.errs(s, i, c, strcmp(d{1}, 'lmmse') + 1) = r.errs;
                    end
                end
            end
            fprintf('%s done\n', scen{s});
        end
        out.scen = scen;  out.xis = xis;  out.c2s = c2s;  out.dets = {'mp-top', 'lmmse'};

    case 'drift'
        Tupd = [0.02 0.2 0.5 1 2];
        pDesign = sys_params('LEO-Ka', 'elev', 90);            % c1 designed for 20 ms
        for i = 1:numel(Tupd)
            p = sys_params('LEO-Ka', 'elev', 90, 'Tupd', Tupd(i));
            pFixed = p;  pFixed.c1 = pDesign.c1;                 % hardware ROM not reloaded
            cfg = {pFixed, 'AFDM'; p, 'AFDM'; p, 'OTFS-Zak'};
            for k = 1:3
                for d = {'mp-top', 'lmmse'}
                    opt = base;  opt.det = d{1};
                    r = ber_curve(cfg{k, 1}, cfg{k, 2}, 18, opt);
                    out.ber(i, k, strcmp(d{1}, 'lmmse') + 1) = r.ber;
                end
            end
            out.alpha(i) = p.alpha_max;  out.nuRes(i) = p.nu_common_max;
            fprintf('Tupd %.2f s: alpha_max %d, residual %.0f Hz\n', Tupd(i), p.alpha_max, p.nu_common_max);
        end
        out.Tupd = Tupd;  out.cfg = {'AFDM, c1 fixed (20 ms)', 'AFDM, c1 re-designed', 'OTFS-Zak'};
        out.dets = {'mp-top', 'lmmse'};

    case 'profiles'
        profs = {'NTN-TDL-A', 'NTN-TDL-B', 'NTN-TDL-C', 'NTN-TDL-D'};
        DS = [100e-9 300e-9 1000e-9];
        names = {'AFDM', 'OTFS-Zak'};
        for a = 1:numel(profs)
            for b = 1:numel(DS)
                p = sys_params('LEO-Ka', 'profile', profs{a}, 'DS', DS(b));
                for n = 1:2
                    for d = {'mp-top', 'lmmse'}
                        opt = base;  opt.det = d{1};
                        r = ber_curve(p, names{n}, 18, opt);
                        out.ber(a, b, n, strcmp(d{1}, 'lmmse') + 1) = r.ber;
                    end
                end
                out.Ncp(a, b) = p.Ncp;
                out.lmax(a, b) = max(tdl_profile(profs{a}).delay) * DS(b) / p.Ts;
            end
            fprintf('%s done\n', profs{a});
        end
        out.profs = profs;  out.DS = DS;  out.names = names;  out.dets = {'mp-top', 'lmmse'};

    case 'numerology'
        Bs = [0.96e6 1.92e6 3.84e6];  scen = {'V2X', 'LEO-Ka'};  snr = [8 16 24];
        names = {'AFDM', 'OTFS-Zak'};
        for s = 1:2
            for b = 1:numel(Bs)
                p = sys_params(scen{s}, 'B', Bs(b));
                for n = 1:2
                    for d = {'mp-top', 'lmmse'}
                        opt = base;  opt.det = d{1};
                        r = ber_curve(p, names{n}, snr, opt);
                        out.ber(s, b, n, strcmp(d{1}, 'lmmse') + 1, :) = r.ber;
                    end
                end
                out.alpha(s, b) = p.alpha_max;
                out.nuNorm(s, b) = (p.nu_path_max + p.nu_common_max) * p.T;
            end
            fprintf('%s done\n', scen{s});
        end
        out.Bs = Bs;  out.scen = scen;  out.snr = snr;  out.names = names;  out.dets = {'mp-top', 'lmmse'};

    case 'qam16'
        p = sys_params('LEO-Ka', 'Q', 16);  snr = 0:4:28;  names = {'AFDM', 'OTFS-Zak'};
        for n = 1:2
            for d = {'mp-top', 'lmmse'}
                opt = base;  opt.det = d{1};
                r = ber_curve(p, names{n}, snr, opt);
                out.ber(n, strcmp(d{1}, 'lmmse') + 1, :) = r.ber;
                out.errs(n, strcmp(d{1}, 'lmmse') + 1, :) = r.errs;
            end
        end
        out.snr = snr;  out.names = names;  out.dets = {'mp-top', 'lmmse'};

    otherwise
        error('study_small:which', 'Unknown study "%s".', which);
end
out.base = base;
save(fullfile(results_dir(), ['small_' which '.mat']), 'out');
fprintf('Saved results/small_%s.mat\n', which);
end
