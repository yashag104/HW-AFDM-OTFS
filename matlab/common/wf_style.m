function st = wf_style(name)
% WF_STYLE  Fixed plot style per waveform, so every figure uses the same identity.
%   name : 'AFDM' | 'OTFS-Zak' | 'OTFS-ISFFT'
%   st   : struct with color (RGB), marker, line
% Colors are the first three slots of a CVD-validated categorical palette;
% the marker and line style are a second cue for grayscale print.
switch name
    case 'AFDM',       hex = '2a78d6'; st.marker = 'o'; st.line = '-';
    case 'OTFS-Zak',   hex = 'eb6834'; st.marker = 's'; st.line = '--';
    case 'OTFS-ISFFT', hex = '1baf7a'; st.marker = '^'; st.line = ':';
    otherwise, error('wf_style:name', 'Unknown waveform "%s".', name);
end
st.color = sscanf(hex, '%2x%2x%2x').' / 255;
end
