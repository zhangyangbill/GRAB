function cleanest_channel = find_cleanest_channel(s)
% This function finds the cleanest channel by computing the lower quantiles
%
% Input:
% s - each column is a channel of signal
%
% Output:
% cleanest_channel - the index of the estimated cleanest channel

num_channels = size(s, 2);

% compute the quatiles of each channel
q = quantile(abs(s), 0.4);

% compute quantile energy ratios
qr = zeros(num_channels, 1);
for channel_id = 1 : num_channels
    qr(channel_id) = norm(s(abs(s(:, channel_id)) < q(channel_id), channel_id))...
        / norm(s(:, channel_id));
end

[~, cleanest_channel] = min(qr);

end