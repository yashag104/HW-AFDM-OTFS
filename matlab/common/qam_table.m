function [const, bits] = qam_table(Q)
% QAM_TABLE  Gray-coded square QAM constellation with unit average energy.
%   Q     : constellation size (4, 16, 64, ...)
%   const : Q x 1 complex points; const(i) is symbol index i-1
%   bits  : Q x log2(Q) bit labels of each symbol index
%
% The first half of the bits select the in-phase level and the second half
% the quadrature level; each half is Gray coded along its axis.

m  = log2(Q);
mh = m / 2;
assert(mh == round(mh), 'qam_table: Q must be a square QAM order.');

L      = 2^mh;                               % levels per axis
levels = -(L - 1):2:(L - 1);
gray   = bitxor(0:L - 1, bitshift(0:L - 1, -1));   % gray(k+1) = code at position k

const = zeros(Q, 1);
bits  = zeros(Q, m);
for i = 0:Q - 1
    bits(i + 1, :) = dec2bin(i, m) - '0';
    codeI = floor(i / L);                    % first mh bits
    codeQ = mod(i, L);                       % last mh bits
    const(i + 1) = levels(gray == codeI) + 1j * levels(gray == codeQ);
end
const = const / sqrt(mean(abs(const).^2));
end
