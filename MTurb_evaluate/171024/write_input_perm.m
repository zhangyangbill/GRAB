% write input permutation

% output file path
fid = fopen('input_perm.csv', 'w+');

alg = {'closest', 'grab', 'mvdr', 'iva', 'deepbeam'};
speaker = {'Dinei', 'Yang'};

fprintf(fid, '%s\n', 'url1,alg1,url2,alg2,url3,alg3,url4,alg4,url5,alg5');

for speaker_id = 1 : 2
    for noise_id = 1 : 5
        for speech_id = 1 : 6
            % skip the first sentence of dinei
            if speaker_id == 1
                speech_cur = speech_id + 1;
            else
                speech_cur = speech_id;
            end
            % generate random permuation
            rp = randperm(5);
            for alg_id = 1 : 5
                fprintf(fid, '%s', ...
                    ['https://raw.githubusercontent.com/zhangyangbill/GRAB/master/MTurb_evaluate/171024/',...
                    speaker{speaker_id}, '/', alg{rp(alg_id)},...
                    '_n', num2str(noise_id),...
                    '_s', num2str(speech_cur),...
                    '.wav,']);
                fprintf(fid, '%s', alg{rp(alg_id)});
                if alg_id < 5
                    fprintf(fid, '%s', ',');
                else
                    fprintf(fid, '\n');
                end
            end
        end
    end
end
fclose(fid);