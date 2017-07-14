function [s_beamformed, noise_beamformed, h] = model_based_beamforming(s, noise,...
    frame_len, frame_len_lpc, h_order, num_iterations, lpc_order, fs)
% This functions is the integrated function to perform adaptive beamforming
% on s using the method in
% Yang Zhang, Dinei Florencio, Mark Hasegawa-Johnson, "GLOTTAL MODEL BASED
% SPEECH BEAMFORMING FOR AD-HOC MICROPHONE ARRAYS", INTERSPEECH2017
%
% Input:
% s - the input signal, each column is a channel
% noise - the input signal with noise only
% frame_len - frame length
% frame_len_lpc - frame length for LPC analysis
% h_order - the beamforming coefficients order
% num_iterations - the number of iterations for each frame
% lpc_order - the order of LPC
% fs - the sampling frequency of the input speech
% mic_pos - the microphone positions in x y z coordinates
% src_pos - the source positions in x y z coordinates
%
% Output:
% s_beamformed - beamformed speech
% noise_beamformed - beamformed noise
% h - beamforming filter coefficients

num_channels = size(s, 2);
num_frames = floor(size(s, 1) / frame_len);
s_beamformed = zeros(size(s, 1), 1);
noise_beamformed = s_beamformed;

% define initial states of the filters
zi_lpc = []; % LPC filter of the beamformed signal
zi_aux_lpc = []; % LPC filter of each channel
zf_lpc = []; % LPC filter of the beamformed signal
zf_aux_lpc = []; % LPC filter of each channel
zi_beamform = []; % the beamform filter
zi_noise_beamform = []; % the beamform filter for noise

% initialize the beamformer
closest_mic = find_cleanest_channel(s);
H_init = zeros(h_order, num_channels);
H_init(round(2 * h_order / 3), closest_mic) = 1;

% adaptive beamforming
Rd = [];  % initial guess of the glottal tightness
for t = 1 : num_frames
    % set the beamformer to initial value
    if t == 1
        h = H_init;
    end
    % current index
    current_idx = (t-1) * frame_len + 1 : t * frame_len;
    
    for iter = 1 : num_iterations
        % step 1: obtain the beamformed signal
        [s_beamformed_temp, ~]...
            = beamform_filter_time(s(current_idx, :), h, zi_beamform);

        % step 2: obtain the LPC residual
        [e, e_aux, zf_lpc, zf_aux_lpc, a] = lpc_residual_precise(s_beamformed_temp,...
            s(current_idx, :), frame_len_lpc, lpc_order, zi_lpc, zi_aux_lpc, [], [], h);
        
        % step 3: extract voiced excitation out of the LPC residual
        if iter == 1
            [ev, Rd, ~] = find_ev(e, fs, frame_len_lpc, lpc_order, Rd, iter, s_beamformed_temp);
        end
        
        
        % step 4: Weiner filter to update h
        h = update_beamform_coef(e_aux, ev, h_order);
        
        disp(['Interation ', num2str(iter), ' completed.'])
    end
    
    % apply final filter to produce the output
    [s_beamformed(current_idx), zf_beamform]...
        = beamform_filter_time(s(current_idx, :), h, zi_beamform);
    [noise_beamformed(current_idx), zf_noise_beamform]...
        = beamform_filter_time(noise(current_idx, :), h, zi_noise_beamform);
    
    % the final states are the initial states for the next frame
    zi_beamform = zf_beamform;
    zi_noise_beamform = zf_noise_beamform;
    zi_lpc = zf_lpc;
    zi_aux_lpc = zf_aux_lpc;
end

end