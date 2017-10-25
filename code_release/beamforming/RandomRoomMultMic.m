function [y, imp_resp, EnerDirectSig, EnerReverb, ReverbTime, RoomSize, MicPos,...
    SourcePos, y_noise]...
    = RandomRoomMultMic(x, fs, num_mics, reverb_time)
% This function simulate a room with multiple sources and multiple
% microphones.
%
% Input:
% x - input clean speech; each column corresponds to a source
% fs - sampling frequency in Hz
% num_mics - number of microphones
%
% Output:
% y1 - a matrix of reverberant signals, each column is a speech signal.
% There are num_mics number of signals
% EnergyDirectSig - energy of the direct signal
% EnerReverb - energy of the pure reverberation
% ReverbTime - reverberation time
% RoomSize - the size of the room
% MicPos - the position of the microphone
% SourcePos - the position of the source, each column is the 3-D coordinate
% y_noise - the matrix of reverberant noise, corresponding to source 2 to
% end

% % make sure all the necessary files are in path
% addpath('C:\Users\yzhan143\My Research\2016_MSR_intern\MSR_intern_new\code\data_prep\Reverb8Mics');

% number of sources
num_srcs = size(x, 2);

MinRoomSizeXYZ = [2.5; 2.5; 2.5];
MaxRoomSizeXYZ = [10; 10; 5];

if exist('reverb_time', 'var') && ~isempty(reverb_time)
    MinReverbTime = reverb_time/1000;
    MaxReverbTime = reverb_time/1000;
else
    MinReverbTime = 100/1000;
    MaxReverbTime = 100/1000;
end

%Randomly select sixe of room:
RoomSize = MinRoomSizeXYZ + rand(3,1).*(MaxRoomSizeXYZ-MinRoomSizeXYZ);
ReverbTime = MinReverbTime + rand(1)*(MaxReverbTime-MinReverbTime);

SourcePos = bsxfun(@times, rand(3,num_srcs), RoomSize);
MicPos = bsxfun(@times, rand(3,num_mics), RoomSize);
% %%%%%%% remove!!! %%%%
% SourcePos(:, 2) = SourcePos(:, 1) + SourcePos(:, 2) ./ RoomSize *0.1;
% MicPos(:, 1) = SourcePos(:, 1) + MicPos(:, 1) ./ RoomSize * 0.1;
% %%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%% test! All the mics & sources are at the same height %%%%%%%%%
SourcePos(3, :) = SourcePos(3, 1);
MicPos(3, :) = SourcePos(3, 1);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

speed = 342;        % speed of sounds, in m/s

N = ceil(ReverbTime*fs);  % suggested size of impulse response

a = exp(-13.82/(speed*(1/RoomSize(1)+1/RoomSize(2)+1/RoomSize(3))*ReverbTime));  % estimated absorption coefficient

% add reverberation channel by channel
y = cell(num_mics, 1);
y_noise = cell(num_mics, 1);
imp_resp = zeros(N, num_mics);
for mic_id = 1 : num_mics
    y{mic_id} = zeros(size(x, 1), 1);
    for src_id = 1 : num_srcs
        [hr1, DirGain1]= room(N,SourcePos(1, src_id), SourcePos(2, src_id),...
            SourcePos(3, src_id),...
            MicPos(1, mic_id),MicPos(2, mic_id), MicPos(3, mic_id),...
            RoomSize(1), RoomSize(2), RoomSize(3), a, fs);

        y{mic_id} = y{mic_id} + fftfilt(hr1,x(:, src_id));
        if src_id == 1
            y_noise{mic_id} = - y{mic_id}; % remove the source
        end
%         maxY=max(abs(y{mic_id}));
%         y{mic_id} = y{mic_id} / maxY;
        if src_id == 1
            imp_resp(:, mic_id) = hr1;
        end
    end
    y_noise{mic_id} = y_noise{mic_id} + y{mic_id}; % recover the noise
end
y = cell2mat(y');
y_noise = cell2mat(y_noise');

EnerX = sum(var(x));
EnerDirectSig = EnerX * DirGain1^2; % / (maxY^2);
EnerReverb = sum(var(y))-EnerDirectSig;

end