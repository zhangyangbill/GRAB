function [X_out, X_in] = beamform_filter(s, H, frame_len, frame_shift)
% This function produces the spectrogram of the beamformed signal.
%
% Input:
% s - the matrix of multichannel signals, each column is a signal
% H - the beamforming filter coefficnets, each column is a channel, each
% row is a frequency bin
% frame_len - the frame length
% frame_shift - the frame shift
%
% Output:
% X_out - output spectrogram, each row is a frequency bin, each column is a
% time bin
% X_in - input spectrogram, each row is a frequency bin, each column is a
% channel, the third dimension is time bin

% frame the input speech
num_channels = size(s, 2);
num_frames = floor((size(s, 1) - frame_len) / frame_shift) + 1;
nfft = frame_len / 2 + 1;
X_in = zeros(nfft, num_frames, num_channels);
for cid = 1 : num_channels
    X_temp = spectrogram(s(:, cid), ones(frame_len, 1), frame_len - frame_shift, frame_len, 'onesided');
    X_in(:, :, cid) = X_temp;
end

% produce output spectrogram
X_out = sum(bsxfun(@times, X_in, permute(H, [1, 3, 2])), 3);

end