function [y, zf] = beamform_filter_time(s, h, zi)
% This function beaform filters the signals into 1 clean signal
%
% Input:
% s - input speech matrix. Each column is a channel
% h - filtering coefficients. Each column is a channel
% zi - initial condition. Each column is a channel
%
% Ouput:
% y - beamformed signal
% zf - final condition. Each column is a channel

if nargin <= 2 || isempty(zi)
    zi = zeros(size(h, 1) - 1, size(h, 2));
end

zf = zeros(size(h, 1) - 1, size(h, 2));
s_filtered = zeros(size(s));
num_channels = size(s, 2);

% filter channel by channel
for channel_idx = 1 : num_channels
    [s_filtered(:, channel_idx), zf(:, channel_idx)]...
        = filter(h(:, channel_idx), 1, s(:, channel_idx), zi(:, channel_idx));
end
y = sum(s_filtered, 2);
end