%% write results

noise_seq = [3 2 1 5 4];
speaker = {'Dinei', 'Yang'};
method = {'grab', 'closest', 'iva', 'mvdr'};
from_dir = 'C:\Users\yzhan143\My Research\2016_MSR_intern\MTurb_evaluate\170313\';

for nid = 1 : 5
    for sp_id = 1 : 2
        for mt_id = 1 : 4
            % read audio
            s1 = audioread([from_dir, speaker{sp_id}, '\', method{mt_id}, '_n', num2str(noise_seq(nid)), '_s1.wav']);
            s2 = audioread([from_dir, speaker{sp_id}, '\', method{mt_id}, '_n', num2str(noise_seq(nid)), '_s2.wav']);
            audiowrite(['n', num2str(nid), '_sp', num2str(sp_id), '_mt', num2str(mt_id), '.wav'], [s1; s2], 16000);
        end
    end
end

%% write pure speech
% high pass filter
h = firpm(300, [0 30/8000 70/8000 1], [0 0 1 1], [1, 10]);

for ch_id = 1 : 8
    [s1, fs] = audioread(['C:\Users\yzhan143\My Research\2016_MSR_intern\data2\Dinei2\Track ', num2str(ch_id), '_015.wav']);
    s1 = resample(s1, 16000, fs);
    s1 = filter(h, 1, s1);
    s1 = s1 / max((abs(s1)));
    audiowrite(['pure_speech_', num2str(ch_id), '.wav'], s1(5.185 * 16000 : 10.622 * 16000), 16000);
end

%% write pure noise
rt_dir = 'C:\Users\yzhan143\My Research\2016_MSR_intern\data2\';
% high pass filter
h = firpm(300, [0 30/8000 70/8000 1], [0 0 1 1], [1, 10]);
noise_seq = [3 2 1 5 4];

for n_id = 1 : 5
    D = dir([rt_dir, 'noise', num2str(noise_seq(n_id)), '\Track 3*.wav']);
    [s1, fs] = audioread([rt_dir, 'noise', num2str(noise_seq(n_id)), '\', D(1).name]);
    s1 = resample(s1, 16000, fs);
    s1 = filter(h, 1, s1);
    s1 = s1 / max((abs(s1)));
    audiowrite(['pure_noise_', num2str(n_id), '.wav'], s1(5.185 * 16000 : 10.622 * 16000), 16000);
end