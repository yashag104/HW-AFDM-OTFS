function lay = pilot_layout(name, p)
% PILOT_LAYOUT  Pilot, guard and data positions of one waveform's frame.
%   name : waveform name
%   p    : parameters (N, M, K, Lg, alpha_max, xi)
%   lay  : struct with
%            xp      - N x 1 pilot vector (zeros except the pilots)
%            dataIdx - indices of the data symbols
%            obsIdx  - received samples the channel estimator uses
%
% Every layout keeps the frame energy equal to an all-data frame:
% pilot energy = number of reserved (pilot + guard) positions.
%   AFDM : one pilot at N/2 with Q guard symbols each side,
%          Q = (Lg+1)(2a+1) - 1 + a, a = alpha_max + xi (covers every path
%          position 2N*c1*l - alpha for l <= Lg, plus Doppler spread)
%   OTFS : embedded pilot at (M/2, K/2); guard = delay rows M/2 +/- Lg over
%          the whole Doppler axis (fractional Doppler spreads along it)
%   OFDM : comb pilots on every 4th subcarrier, no guard (pilot overhead
%          only: with one OFDM symbol per frame the comb cannot resolve
%          Doppler beyond +/-2 bins, so OFDM is run with genie CSI)
N   = p.N;
res = false(N, 1);              % reserved (pilot or guard) positions
switch name
    case 'AFDM'
        a  = p.alpha_max + p.xi;
        Q  = (p.Lg + 1) * (2 * a + 1) - 1 + a;
        m0 = N / 2;                                   % 0-based pilot index
        res(m0 - Q + 1:m0 + Q + 1) = true;
        pilotIdx = m0 + 1;
    case {'OTFS-Zak', 'OTFS-ISFFT', 'OTFS-PS'}
        l0 = p.M / 2;  k0 = p.K / 2;                  % 0-based pilot position
        G  = false(p.M, p.K);
        G(l0 - p.Lg + 1:l0 + p.Lg + 1, :) = true;     % guard delay rows, all Doppler bins
        res = G(:);
        pilotIdx = l0 + p.M * k0 + 1;
    case 'OFDM'
        res(1:4:N) = true;
        pilotIdx = find(res);
    otherwise
        error('pilot_layout:name', 'Unknown waveform "%s".', name);
end
lay.xp = zeros(N, 1);
lay.xp(pilotIdx) = sqrt(sum(res) / numel(pilotIdx));  % pilot energy = reserved positions
lay.dataIdx = find(~res);
lay.obsIdx  = find(res);
end
