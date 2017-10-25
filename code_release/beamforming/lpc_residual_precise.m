function [e, e_aux, zf, zf_aux, a] = lpc_residual_precise(s, s_aux, frame_len, lpc_order,...
    zi, zi_aux, Rd, fs, h)
% This function obtains the LPC residual. e_aux is such that h * e_aux = e
%
% Input:
% s - the input speech waveform, on which the LPC is performed
% s_aux - the auxiliary inputs to be filtered with exactly the same LPC
% frame_len - the frame length
% lpc_order - the order of LPC analysis
% zi - the initial state of filtering s
% zi_aux - the initial state of filtering s_aux
% Rd - optional, match the spectral tilt of the LPC to glottal tightness Rd
% fs - sampling frequency
% h - the reference beamform filter
%
% Output:
% e - LPC residual of s
% e_aux - LPC residual of s_aux
% zf - the final state of filtering s
% zf_aux - the final state of filtering s_aux
% a - the LPC coefficient for each frame

% frame the speech signal
s_framed = buffer(s, frame_len, 0);
num_frames = floor(size(s, 1) / frame_len);

% perform LPC inverse filtering frame by frame
e = zeros(size(s));
e_aux = zeros(size(s_aux));
if ~exist('zi', 'var') || ~exist('zi_aux', 'var')
    zi = [];  % final states of the filter to ensure continuity
    zi_aux = [];
end

a = cell(num_frames, 1);
for t = 1 : num_frames
    a{t} = lpc(s_framed(:, t), lpc_order);
%     a{t} = lpc(s_ref_framed(:, t), lpc_order);
    a{t}(isnan(a{t})) = 0; % safeguard step to prevent all zero in s_frame(:, t)
%     % regularize such that all poles lie within the unit circle
%     K_temp = tf2latc(1, a{t});
%     K_temp(K_temp > 0.95) = 0.95;
%     [num, a{t}] = latc2tf(K_temp, 'allpole');
    if exist('Rd', 'var') && ~isempty(Rd)
        a_tilt = lpc(s_framed(:, t), 3);
        G = gen_glottal_wave(Rd(t), 0.005 * fs, frame_len);
        G = [G(round(frame_len/2) : end); G(1 : round(frame_len/2)-1)];
        G_tilt = lpc(G, 3);
        [e((t-1) * frame_len + 1 : t * frame_len), zi] = filter(conv(a{t}, G_tilt), a_tilt, s_framed(:, t), zi);
    else
        [e((t-1) * frame_len + 1 : t * frame_len), zi] = filter(a{t}, 1, s_framed(:, t), zi);
    end

    if ~isempty(s_aux)
        if exist('Rd', 'var') && ~isempty(Rd)
            [e_aux((t-1) * frame_len + 1 : t * frame_len, :), zi_aux]...
                = filter(conv(a{t}, G_tilt), a_tilt, s_aux((t-1) * frame_len + 1 : t * frame_len, :), zi_aux);
        else
            [e_aux((t-1) * frame_len + 1 : t * frame_len, :), zi_aux]...
                = filter(a{t}, 1, s_aux((t-1) * frame_len + 1 : t * frame_len, :), zi_aux);
        end
    end
    if any(isnan(e((t-1) * frame_len + 1 : t * frame_len)))
        disp('help')
    end
end

% assign final states
zf = zi;
zf_aux = zi_aux;

% only perform corrections on non-zero channels
nz_channel = any(h ~= 0);

% find the approximation error
e_approx = beamform_filter_time(e_aux, h, []);
err_approx = e - e_approx;

% turn everything in frequency domain (ignore aliasing)
ERR_approx = fft(err_approx);
H = fft(h, length(err_approx));
R = bsxfun(@times, conj(H), ERR_approx ./ sum(abs(H).^2, 2));
e_aux(:, nz_channel) = e_aux(:, nz_channel) + real(ifft(R(:, nz_channel)));

end