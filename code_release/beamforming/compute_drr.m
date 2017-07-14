function drr = compute_drr(imp_resp, s_ref, h)
% This function computes the direct to reverberation
%
% Input:
% imp_resp - an matrix of impulse responses functions
% s_ref - the reference signal
% h - beamform filter coefficients
%
% Output:
% drr - direct to reverberation ratio

% obtain the beamformed impulse response
imp_resp_temp =...
    beamform_filter_time(imp_resp, h, []);

% separate the direct path with the rest
[~, peak_id] = max(imp_resp_temp);
peak_id = max(peak_id - 100, 1) : min(peak_id + 100, size(imp_resp, 1));
% direct path and reverberation
direct_path = imp_resp_temp(peak_id);
reverb = imp_resp_temp;
reverb(peak_id) = 0;
% compute the energy of direct path and reverberation
e_direct_path = norm(fftfilt(direct_path, s_ref));
e_reverb = norm(fftfilt(reverb, s_ref));
% compute the signal to reverberation ratio
drr = 20 * log10(e_direct_path / e_reverb);

end