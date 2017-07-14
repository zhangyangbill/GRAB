function x = inv_spectrogram(X, frame_len, frame_shift)
% This function recover the signal from spectrogram using overlap-add
% method
%
% Inputs:
% X - spectrogram
% frame_len - frame length
% frame_shift - frame shift
%
% Outputs:
% x - recovered time-domain signal

% compute the dimension
num_frames = size(X, 2);

% preallocate space for the output
x = zeros(1 + frame_shift * (num_frames - 1) + frame_len, 1);

X_ifft = ifft([X; conj(X(end-1 : -1 : 2, :))], frame_len, 1, 'symmetric');

for frame_id = 1 : num_frames
    x((frame_id-1) * frame_shift + 1 : (frame_id-1) * frame_shift + frame_len)...
        = X_ifft(:, frame_id);
end

end