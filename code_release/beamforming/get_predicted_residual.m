function r = get_predicted_residual(s, e, frame_len, lpc_order)
% This function get the predicted residual from the waveform file s by
% overlapp-add
%
% Input:
% s - the input waveforms, each column is a waveform
% e - the LPC residual of s
% frame_len - the frame length
% lpc_order - the order of LPC analysis
%
% Output:
% r - the predicted residual

num_channels = size(s, 2);

% data processing (copy from write_all_wave2.wav)
r = cell(1, num_channels);
for channel_id = 1 : num_channels
    % normalize
    s_temp = s(:, channel_id) / max(s(:, channel_id));
    % obtain LPC residual
    s_temp = lpc_residual(s_temp, [], 480, 10);
    % partition in frames
    frame_len = 480;
    frame_shift = 160;
    
    frame = fft(buffer(s_temp, frame_len, frame_len - frame_shift)) / sqrt(frame_len);
    frame = [real(frame(1 : round(frame_len / 2) + 1, :));...
        imag(frame(2 : round(frame_len / 2), :))];
    
    % get neural network output
    [feature_clean, feature_dirty] = readFeatures('C:\Users\t-yazha\MSR_intern\generative model\Data\timit_lpc_train_small.txt', 10000, 480);
    
    rootDir = 'C:\Users\t-yazha\MSR_intern\generative model\';
    Y = get_nn_output(feature_clean, feature_dirty, [rootDir, 'Data\'], [rootDir, 'Config\'],...
        [rootDir, 'Output\']);
    
    % perform overlap-add method
    num_frames = size(Y, 2);
    r{channel_id} = zeros(length(e(:, 1)), 1);
    for frame_id = 1 : num_frames
        idx_temp = (frame_id - 1) * frame_shift + 1 : (frame_id - 1) * frame_shift + frame_len;
        if any(idx_temp > size(e, 1))
            break
        end
        Y_temp = [Y(1:round(frame_len/ 2)+1, frame_id); flipud(Y(2:round(frame_len/ 2), frame_id))];
        Y_temp(2 : round(frame_len/ 2)) = Y_temp(2 : round(frame_len/ 2))...
            + 1j * Y(round(frame_len/ 2)+2 : end, frame_id);
        Y_temp(round(frame_len/ 2)+2 : end) = Y_temp(round(frame_len/ 2)+2 : end)...
            - 1j * flipud(Y(round(frame_len/ 2)+2 : end, frame_id));
        Y_temp = real(ifft(Y_temp)) * sqrt(frame_len);
        r{channel_id}(idx_temp) = r{channel_id}(idx_temp)...
            + Y_temp .* hamming(frame_len);
    end
end
r = cell2mat(r);

% % equalize the residual by running LPC residual again
% r = lpc_residual(r, [], frame_len, lpc_order);

% % match the energy
% r = r / norm(r) * norm(e);


end