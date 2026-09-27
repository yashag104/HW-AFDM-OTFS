function g = rc_pulse(x, alpha)
% RC_PULSE  Raised-cosine pulse (transmit and receive filters combined).
%   x     : time in samples (any array)
%   alpha : roll-off in [0, 1]
%   g     : pulse value; g(0) = 1 and g(k) = 0 at every other integer k,
%           so an on-grid delay reduces to a pure sample shift.
s = ones(size(x));
nz = x ~= 0;
s(nz) = sin(pi * x(nz)) ./ (pi * x(nz));                   % sinc (base MATLAB has none)
den = 1 - (2 * alpha * x).^2;
g = s .* cos(pi * alpha * x) ./ den;
sing = abs(den) < 1e-12;                                    % |x| = 1/(2 alpha): use the limit
g(sing) = (pi / 4) * s(sing);
end
