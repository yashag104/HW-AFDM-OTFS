function h = plot_ber(ax, x, r, name, label, faded)
% PLOT_BER  One BER curve with its 95 % confidence interval as error bars.
%   ax    : axes (log y)
%   x     : x values (SNR, taps, ...)
%   r     : result struct from ber_curve, or a struct array with one entry per x
%   name  : waveform name (sets colour, marker and line style via wf_style)
%   label : legend text
%   faded : optional, true draws a lighter, thinner variant (default false)
%   h     : line handle (for the legend)
% Points with zero errors are not drawn (their BER is only bounded above).
if nargin < 6, faded = false; end
if numel(r) > 1                                   % struct array over x
    ber = [r.ber];  lo = [r.lo];  hi = [r.hi];
else
    ber = r.ber;    lo = r.lo;    hi = r.hi;
end
st  = wf_style(name);
col = st.color;
lw  = 1.5;
if faded, col = 0.45 * col + 0.55 * [1 1 1]; lw = 1.1; end
ok  = ber > 0;
h = errorbar(ax, x(ok), ber(ok), ber(ok) - lo(ok), hi(ok) - ber(ok), 'LineStyle', st.line, ...
             'Color', col, 'Marker', st.marker, 'MarkerSize', 7, 'LineWidth', lw, ...
             'CapSize', 3, 'DisplayName', label);
end
