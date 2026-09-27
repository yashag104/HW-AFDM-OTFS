function st = wf_style(name)
% WF_STYLE  Fixed plot style per waveform, so every figure uses the same identity.
%   name : 'AFDM' | 'OTFS-Zak' | 'OTFS-ISFFT' | 'OTFS-PS' | 'OFDM'
%   st   : struct with color (RGB), marker, line
% Colors follow a CVD-validated categorical palette in fixed order; the
% marker and line style are a second cue for grayscale print.
switch name
    case 'AFDM',       hex = '2a78d6'; st.marker = 'o'; st.line = '-';
    case 'OTFS-Zak',   hex = 'eb6834'; st.marker = 's'; st.line = '--';
    case 'OTFS-ISFFT', hex = '1baf7a'; st.marker = '^'; st.line = ':';
    case 'OTFS-PS',    hex = 'e87ba4'; st.marker = 'd'; st.line = '-.';
    case 'OFDM',       hex = '4a3aa7'; st.marker = 'x'; st.line = '-';
    otherwise, error('wf_style:name', 'Unknown waveform "%s".', name);
end
st.color = sscanf(hex, '%2x%2x%2x').' / 255;
end
