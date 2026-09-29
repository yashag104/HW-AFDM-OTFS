function fxc = fx_config(Wd, Wt, Wc)
% FX_CONFIG  Fixed-point formats used by the transform datapaths.
%   Wd  : data word length [bits]   (samples, butterfly outputs)
%   Wt  : FFT twiddle ROM word length [bits]
%   Wc  : AFDM chirp ROM word length [bits]
%   fxc : struct of fx() formats: data, tw, chirp
%
% Data uses 3 integer bits (range [-4, 4)): unit-power symbols and unitary
% transforms keep the RMS at 1, leaving about 12 dB of headroom for peaks.
% Twiddles and chirps are on the unit circle, so 2 integer bits hold +1.0.

fxc.data  = struct('W', Wd, 'I', 3);
fxc.tw    = struct('W', Wt, 'I', 2);
fxc.chirp = struct('W', Wc, 'I', 2);
% One-tap equalizer gains (DFT-s-OFDM / OFDM): the largest MMSE gain is
% 1/(2 sqrt(N0)), about 8 at 24 dB, so 5 integer bits ([-16, 16)).
fxc.gain  = struct('W', Wt, 'I', 5);
end
