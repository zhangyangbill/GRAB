function s_matched = match_spect(s, s_ref)
% This function matches the spectral shape of s to s_ref, using filterbank
% approach.

% basic settings
frame_len = 4800;
frame_shift = 1600;
num_freq_bins = 8; % number of frequency bin
filter_tap = 128;

% compute the energy in each subband
S = abs(spectrogram(s, hamming(frame_len), frame_len - frame_shift, frame_len)).^2;
S_ref = abs(spectrogram(s_ref, hamming(frame_len), frame_len - frame_shift, frame_len)).^2;

% compute the energy ratio in each frequency bin
energy_ratio = zeros(num_freq_bins, 1);
for freq_id = 1 : num_freq_bins
    freq_index = round((frame_len / 2 + 1) / num_freq_bins * (freq_id-1)) + 1 :...
     round((frame_len / 2 + 1) / num_freq_bins * freq_id);
    energy_ratio(freq_id) = sum(sum(S_ref(freq_index, :))) / sum(sum(S(freq_index, :)));
end

% normalize and take the square of energy ratio
energy_ratio = sqrt(energy_ratio / max(energy_ratio));

% design an FIR filter that has the freqz characteristic function of energy
% ratio
b = firpm(filter_tap, 0.5/num_freq_bins : 1/num_freq_bins : (1 - 0.5 / num_freq_bins), energy_ratio);

% compute the output by filter
s_matched = filter(b, 1, s);

end