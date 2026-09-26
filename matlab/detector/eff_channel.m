function H = eff_channel(wf, ch, p)
% EFF_CHANNEL  Effective channel in the detection domain, y = H x + w.
%   wf : waveform from waveform() (holds the modulator/demodulator matrices)
%   ch : channel from gen_channel
%   p  : parameters from sys_params
%   H  : N x N matrix = Demod * Hc * Mod, floating point
% This is the genie (perfect CSI) channel the detector is given.
H = wf.DemM * channel_matrix(ch, p, wf.pre, 0) * wf.ModM;
end
