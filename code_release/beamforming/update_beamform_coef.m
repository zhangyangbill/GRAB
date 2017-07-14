function h = update_beamform_coef(r, e, h_order)
% This function updates the beamforming coefficients using Weiner filtering
%
% Input:
% r - Noisy observation. Each column is a channel
% e - target clean speech
% h - the order of the beamforming coefficients
%
% Output:
% h - beamforming coefficients. Each column corresponds to a channel.

num_channels = size(r, 2);
frame_len = size(r, 1);
% Convert to time domain
S = fft(r, 2 ^ nextpow2(2 * size(r, 1) - 1));

% % for numerical stability normlize input energy
% S_norm = sqrt(sum(abs(S) .^ 2));
% S = bsxfun(@rdivide, S, S_norm);

% fill the autocorrelation matrix
R = zeros(num_channels * h_order);
for channel_idx1 = 1 : num_channels
    for channel_idx2 = 1 : channel_idx1
        autocorr_temp = real(ifft(conj(S(:, channel_idx1)) .* S(:, channel_idx2)));
        R_temp = toeplitz(autocorr_temp(1 : h_order) ...
            ,...
            [autocorr_temp(1); autocorr_temp(end : -1 : end-h_order+2)] ...
            );
        R((channel_idx1-1) * h_order + 1 : channel_idx1 * h_order, ...
            (channel_idx2-1) * h_order + 1 : channel_idx2 * h_order) = R_temp;
        if channel_idx1 ~= channel_idx2
            R((channel_idx2-1) * h_order + 1 : channel_idx2 * h_order, ...
                (channel_idx1-1) * h_order + 1 : channel_idx1 * h_order) = R_temp';
        end
    end
end

% cross correlation vector
E = fft(e, 2 ^ nextpow2(2 * length(e) - 1));
xcorr_temp = real(ifft(bsxfun(@times, conj(S), E)));
xcorr_temp = xcorr_temp(1 : h_order, :);
p = xcorr_temp(:);

% compute the beamforming coefficients
h_temp = R \ p;
h = reshape(h_temp, [h_order, num_channels]);

end