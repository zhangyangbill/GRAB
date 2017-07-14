function [s_dirty, noise] = RandomNoise(s, fs, isTrain, SNR)
% This function corrupts the signal with additive noise by randomly
% selecting from noise corpus and SNR.
%
% Input:
% s - input speech
% fs - sampling frequency
% isTrain - true if the sampling noise is from the training corpus
% SNR - optional, specifies the SNR.
%
% Output:
% s_dirty - corrupted speech

% number of file to choose from
persistent train_path % the path of training directory
persistent train_dir % training directory
persistent num_train % number of training files
persistent test_path % the path of test directory
persistent test_dir % testing directory
persistent num_test % numver of test files

if isempty(train_path)
    train_path = '..\office_noise_All\';
end
if isempty(train_dir)
    train_dir = dir([train_path, '*.wav']);
end
if isempty(num_train)
    num_train = length(train_dir);
end
if isempty(test_path)
    test_path = '..\office_noise_All\';
end
if isempty(test_dir)
    test_dir = dir([test_path, '*.wav']);
end
if isempty(num_test)
    num_test = length(test_dir);
end

% randomly select & read noise
if isTrain
    file_id = randi(num_train);
    [noise, noise_fs] = audioread([train_path, train_dir(file_id).name]);
else
    file_id = randi(num_test);
    [noise, noise_fs] = audioread([test_path, test_dir(file_id).name]);
end

% adapt the noise to the input speech
if fs ~= noise_fs % adjust sampling frequency
    noise = resample(noise, fs, noise_fs);
end

% match length
len_noise = length(noise);
len_s = length(s);
if len_noise > len_s
    % randomly select a segment if it is too long
    start_idx = randi(len_noise - len_s + 1);
    noise = noise(start_idx : start_idx + len_s - 1);
else
    % pad if it is too short
    speech_idx = 0 : len_s-1;
    noise = noise(mod(speech_idx, len_noise) + 1);
end

% mix with a random SNR
power_s = mean(s .^ 2);
power_noise = mean(noise .^ 2);
if ~exist('SNR', 'var') || isempty(SNR)
    SNR = rand * 10 + 20;   % randomly draw SNR from -10dB to 30dB
end
noise = noise * sqrt(power_s / power_noise / (10 ^ (SNR / 10)));
s_dirty = s + noise;