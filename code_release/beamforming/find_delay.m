function [delay, amp, H_init] = find_delay(s, frame_len, frame_shift, closest_channel)
% This function estimates the relative delays among channels using PHAT
% cross correlation and propose the simple delay and sum beamformer
%
% Input:
% s - speech signals, each column is a channel
% frame_len - the frame length
% frame_shift - the frame shift
% closest_channel - optional, specifies which one is the closest channel
%
% Output:
% delay - a column vector of relative delay in samples. The closest channel
% will have 0 delay
% amp - relative amplitude (relative to the cloest source)
% H_init - delay and sum beamformer. Each row is a frequency bin, each
% column is a channel. H_init is also the conjugate of signal transfer
% function.

num_channels = size(s, 2);

% obtain spectrogram
S = cell(num_channels, 1); % spectrogram of each channel
sqrt_energy = cell(num_channels, 1); % frame square-root energy of each channel
for cid = 1 : num_channels
    S{cid} = spectrogram(s(:, cid), hamming(frame_len), frame_len - frame_shift, frame_len, 'twosided');
    sqrt_energy{cid} = sqrt(sum(abs(S{cid}) .^ 2));
end

% initial PHAT estimation (w.r.t channel 1)
delay = ones(num_channels, 1);
R = ones(num_channels, num_channels);
for cid = 2 : num_channels
%     cross_corr_spect = bsxfun(@rdivide, conj(S{1}) .* S{cid},...
%         sqrt_energy{1} .* sqrt_energy{cid}); % cross PSD normalized by energy
    cross_corr_spect = conj(S{1}) .* S{cid};
    cross_corr = mean(ifft(cross_corr_spect), 2) * frame_len; % frame_len is due to DFT transform constant
    cross_corr_spect_norm = cross_corr_spect ./ abs(cross_corr_spect);
    valid_cols = ~isnan(sum(cross_corr_spect_norm));
    cross_corr_norm = sum(ifft(cross_corr_spect_norm(:, valid_cols)), 2);
    [~, delay(cid)] = max(abs(cross_corr_norm));
    R(cid, 1) = cross_corr(delay(cid));
    R(1, cid) = cross_corr(delay(cid));
    delay(cid) = mod(delay(cid) + frame_len / 2, frame_len) - frame_len / 2;
end

% second round PHAT estimation (w.r.t the closest channel)
if ~exist('closest_channel', 'var')
    [~, closest_channel] = min(delay);
end

if closest_channel ~= 1
    delay(1)= -delay(closest_channel);
    for cid = [2 : closest_channel-1, closest_channel+1 : num_channels]
%         cross_corr_spect = bsxfun(@rdivide, conj(S{closest_channel}) .* S{cid},...
%             sqrt_energy{1} .* sqrt_energy{cid});
        cross_corr_spect = conj(S{closest_channel}) .* S{cid};
        cross_corr = mean(ifft(cross_corr_spect), 2) * frame_len;
        cross_corr_spect_norm = cross_corr_spect ./ abs(cross_corr_spect);
        valid_cols = ~isnan(sum(cross_corr_spect_norm));
        cross_corr_norm = sum(ifft(cross_corr_spect_norm(:, valid_cols)), 2);
        [~, delay(cid)] = max(abs(cross_corr_norm));
        R(cid, closest_channel) = cross_corr(delay(cid));
        R(closest_channel, cid) = cross_corr(delay(cid));
        delay(cid) = mod(delay(cid) + frame_len / 2, frame_len) - frame_len / 2;
    end
    delay(closest_channel) = 1;
end

% finish the rest of the amp matrix
for cid1 = [2 : closest_channel-1, closest_channel+1 : num_channels]
    for cid2 = setdiff(cid1+1 : num_channels, closest_channel)
%         cross_corr_spect = bsxfun(@rdivide, conj(S{cid1}) .* S{cid2},...
%             sqrt_energy{cid1} .* sqrt_energy{cid2});
        cross_corr_spect = conj(S{cid1}) .* S{cid2};
        cross_corr = mean(ifft(cross_corr_spect), 2) * frame_len;
        % compute relative delay (in 1 indexing)
        rel_delay = mod(delay(cid2) - delay(cid1), frame_len) + 1;
        R(cid1, cid2) = cross_corr(rel_delay);
        R(cid2, cid1) = cross_corr(rel_delay);
    end
end

% perform iterative rank-1 matrix completion
for iter = 1 : 10
    [V, D] = eigs(R, 1);
    % replace the diagonal elements with rank-1 reconstruction
    R = R - diag(diag(R)) + diag(V.^2 * D);
end
% the amplitude estimate is the normalized V
amp = V / norm(V) * sign(mean(V));

% Matlab is 1-indexing, turn to 0-indexing
% delay = delay - 1;
delay = delay - max(delay) - 1;

% delay and sum beamformer
if nargout > 2
    H_init = bsxfun(@times, exp(1j * 2 * pi * (0 : (frame_len / 2))' * delay' / frame_len)...
        , amp');
end

end