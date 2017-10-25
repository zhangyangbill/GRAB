function g_res = gen_glottal_residual(Rd, T0, frame_len, lpc_order, ev)
% This function generates the glottal residual based on the simplified LF
% model
%
% Input:
% Rd - the glottal tightness parameter for each frame
% T0 - the fundamental period in samples
% frame_len - frame length in samples
% lpc_order - the LPC order
% ev - the GCI peaks
%
% Output:
% g_res - glottal residual

num_frames = length(Rd);

g_res = zeros(size(ev));
for frame_id = 1 : num_frames
    % get the shape of the impulse
    G = gen_glottal_wave(Rd(frame_id), T0, frame_len);
    G = [G(round(frame_len/2) : end); G(1 : round(frame_len/2)-1)];
    a = lpc(G, lpc_order);
    G_res = conv(a', G); % glottal residual of single cycle
    G_res = G_res / max(G_res);

    % convolve GCI with the impulse
    g_res_temp = conv(G_res, ev((frame_id - 1) * frame_len + 1 ...
        : min(frame_id * frame_len, end)));
    % fit the convolution result to g_res
    fit_idx = max((frame_id - 1) * frame_len - round(frame_len/2 + 1), 1) ...
        : min(frame_id * frame_len + round(frame_len/2) - 2, length(ev));
    g_res(fit_idx) = g_res(fit_idx)...
        + g_res_temp(fit_idx - ((frame_id - 1) * frame_len - round(frame_len/2 + 1)) + 1);
end