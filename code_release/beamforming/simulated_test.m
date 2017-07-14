source_ratio_cand = [0 10 20];
reverb_time_cand = [100 200 300];

ns_total = zeros(length(source_ratio_cand), length(reverb_time_cand));
srr_total = zeros(length(source_ratio_cand), length(reverb_time_cand));

for sid = 1 : 3
    for rid = 1 : 3
        source_ratio = source_ratio_cand(sid);
        reverb_time = reverb_time_cand(rid);
        
        for index = 1 : 10
            run main_beamforming2
        end
        ns_total(sid, rid) = mean(noise_suppress);
        srr_total(sid, rid) = mean(srr);
%         result_path = 'C:\Users\yzhan143\My Conferences\ICASSP2017\webpage\';
%         audiowrite([result_path, 'GRAB_E', num2str(source_ratio_cand(sid)), '_R', num2str(reverb_time_cand(rid)), '.wav'],...
%             s_beamformed / max(abs(s_beamformed)) / 2, 16000);
%         audiowrite([result_path, 'MVDR_E', num2str(source_ratio_cand(sid)), '_R', num2str(reverb_time_cand(rid)), '.wav'],...
%             s_beamformed_mvdr / max(abs(s_beamformed_mvdr)) / 2, 16000);
%         audiowrite([result_path, 'Close_E', num2str(source_ratio_cand(sid)), '_R', num2str(reverb_time_cand(rid)), '.wav'],...
%             s(:, closest_mic) / max(abs(s(:, closest_mic))) / 2, 16000);
    end
end