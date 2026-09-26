function y = fx(x, fmt)
% FX  Quantize to signed fixed point, bit-exact with HLS ap_fixed<W,I,AP_RND,AP_SAT>.
%   x   : real or complex array
%   fmt : struct with fields
%           W - total word length [bits]
%           I - integer bits including the sign bit
%   y   : quantized array, same size as x
%
% AP_RND : round half towards +infinity, i.e. floor(v * 2^F + 0.5) / 2^F
% AP_SAT : clip to [-2^(I-1), 2^(I-1) - 2^-F]
% Real and imaginary parts are quantized independently.

F    = fmt.W - fmt.I;           % fractional bits
lsb  = 2^(-F);
vmax = 2^(fmt.I - 1) - lsb;
vmin = -2^(fmt.I - 1);

y = quant(real(x));
if ~isreal(x)
    y = complex(y, quant(imag(x)));
end

    function v = quant(v)
        v = floor(v / lsb + 0.5) * lsb;
        v = min(max(v, vmin), vmax);
    end
end
