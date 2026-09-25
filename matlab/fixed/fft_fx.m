function X = fft_fx(x, inverse, dfmt, tfmt, sched)
% FFT_FX  Bit-true fixed-point radix-2 DIT FFT (golden model for the HLS FFT).
%   x       : L x 1 column vector, L = 2^n
%   inverse : false -> exp(-j 2 pi k n / L), true -> exp(+j 2 pi k n / L)
%   dfmt    : data format, applied to every butterfly output
%   tfmt    : twiddle ROM format
%   sched   : 1 x n logical, true = divide by 2 in that stage
%   X       : L x 1 result in natural order
%
% Butterfly (stage s):  t = b * w            (exact, no rounding)
%                       a' = Q((a + t) * g),  b' = Q((a - t) * g)
% where g = 1/2 if sched(s) else 1, and Q is fx() with dfmt.
% All products are exact in double precision for W <= 26, so the result
% matches an HLS implementation with a full-precision product bit for bit.

L       = numel(x);
nStages = round(log2(L));
assert(2^nStages == L, 'fft_fx: length must be a power of two.');
assert(numel(sched) == nStages, 'fft_fx: one schedule entry per stage.');

if inverse
    sgn = +1;
else
    sgn = -1;
end
tw = fx(exp(sgn * 1j * 2 * pi * (0:L/2 - 1).' / L), tfmt);   % twiddle ROM

X = fx(x(bitrev_index(L)), dfmt);           % input in bit-reversed order

for s = 1:nStages
    half = 2^(s - 1);                       % butterfly distance
    span = 2 * half;                        % butterfly group size
    k    = (0:half - 1).';                  % position inside a group
    ia   = k + (0:span:L - 1) + 1;          % top inputs,    half x (L/span)
    ib   = ia + half;                       % bottom inputs
    w    = tw(k * (L / span) + 1);          % twiddle per position
    g    = 0.5^sched(s);

    a = X(ia);
    t = X(ib) .* w;
    X(ia) = fx((a + t) * g, dfmt);
    X(ib) = fx((a - t) * g, dfmt);
end
end

function idx = bitrev_index(L)
% BITREV_INDEX  1-based bit-reversed permutation of 0..L-1.
n   = round(log2(L));
idx = bin2dec(fliplr(dec2bin(0:L - 1, n))) + 1;
end
