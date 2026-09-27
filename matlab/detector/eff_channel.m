function H = eff_channel(wf, ch, p)
% EFF_CHANNEL  Effective channel in the detection domain, y = H x + w.
%   wf : waveform from waveform() (holds the modulator/demodulator matrices)
%   ch : channel (true, from gen_channel, or estimated, from omp_estimate)
%   p  : parameters from sys_params
%   H  : N x N matrix = Demod * Hc * Mod, floating point
H = wf.DemM * (channel_matrix(ch, p, wf.pre, 0) * wf.ModM);
end
