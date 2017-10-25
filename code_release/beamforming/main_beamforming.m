%% Input Data
% simulate wave
audio_path = '..\timit_examples\';
D = dir([audio_path, '*.wav']);
% randomly pick several audio file
num_files = 10;
s_ref = cell(num_files, 1);
for file_id = 1 : num_files
    [s_ref{file_id}, fs] = audioread([audio_path, D(randi(length(D))).name]);
end
s_ref = cell2mat(s_ref);

num_channels = 8;
source_ratio = 0;
reverb_time = 100;
% generate the noise
[~, noise] = RandomNoise(s_ref, 16000, true, source_ratio);
[s, imp_resp, ~, ~, ~, RoomSize, MicPos, SourcePos, noise]...
    = RandomRoomMultMic([s_ref, noise], 16000, num_channels, reverb_time);
% imp_resp = [zeros(500, num_channels); imp_resp];
delay_true = sqrt(sum(bsxfun(@minus, MicPos, SourcePos(:, 1)) .^ 2)) / 324 * 16000;
delay_true_rel = delay_true' - min(delay_true);

disp('Input data completed.')

%% Perform beamforming
frame_len = size(s, 1);
frame_len_lpc = 480;
h_order = 400;
num_iters = 4;

[s_beamformed, noise_beamformed, H_beamformed] =...
    model_based_beamforming(s, noise, frame_len, frame_len_lpc, h_order,...
    num_iters, 12, 16000);

disp('GRAB completed.')

%% evaluate beamforming
[~, closest_mic] = min(sum(bsxfun(@minus, MicPos, SourcePos(:, 1)) .^ 2));
snr = 20 * log10(norm(s_beamformed - noise_beamformed) / norm(noise_beamformed));
drr = compute_drr(imp_resp, s_ref, H_beamformed);


