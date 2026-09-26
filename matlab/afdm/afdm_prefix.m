function pre = afdm_prefix(p)
% AFDM_PREFIX  Phase of the chirp-periodic prefix (CPP).
%   p   : parameters (N, Ncp, c1)
%   pre : Ncp x 1, s[n] = s[N + n] * pre, for n = -Ncp .. -1
%
% pre(n) = exp(-j 2 pi c1 (N^2 + 2 N n)). For even N and integer 2*N*c1
% (true with the c1 of sys_params) every entry is 1, i.e. the CPP is a
% plain cyclic prefix and costs nothing in hardware.
n   = (-p.Ncp:-1).';
pre = exp(-1j * 2 * pi * p.c1 * (p.N^2 + 2 * p.N * n));
end
