function [shift, w] = path_shifts(tau, p)
% PATH_SHIFTS  Integer sample shifts and pulse weights that realize one delay.
%   tau   : delay [samples]
%   p     : parameters (Kh, rcAlpha)
%   shift : column of integer shifts
%   w     : pulse weight of each shift, rc_pulse(shift - tau)
% An on-grid delay is a single shift with weight 1; a fractional delay is
% spread over the 2*Kh + 2 nearest shifts by the raised-cosine pulse.
if abs(tau - round(tau)) < 1e-12
    shift = round(tau);
    w     = 1;
else
    shift = (floor(tau) - p.Kh:floor(tau) + p.Kh + 1).';
    w     = rc_pulse(shift - tau, p.rcAlpha);
end
end
