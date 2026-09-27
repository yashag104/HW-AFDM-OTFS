function [lo, hi] = ber_ci(errs, bits)
% BER_CI  Exact (Clopper-Pearson) 95 % confidence interval of a bit error rate.
%   errs : bit errors counted
%   bits : bits simulated
%   lo, hi : interval bounds (lo = 0 when errs = 0)
% Treats bits as independent; errors cluster within a frame, so the true
% interval is somewhat wider - quote the number of errors alongside.
if errs == 0
    lo = 0;
else
    lo = betaincinv(0.025, errs, bits - errs + 1);
end
if errs == bits
    hi = 1;
else
    hi = betaincinv(0.975, errs + 1, bits - errs);
end
end
