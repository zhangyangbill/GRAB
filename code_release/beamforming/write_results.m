% select_range_dinei = round(16000 * [0.894 5.185 7.725 10.622 14.806 17.095 20.207...
%     24.213 29.005 33.798 37.052 40.772 44.187 46.387 49.570]);
% select_range_yang = round(16000 * [1.201 2.348 5.435 8.139 13.629 16.333 20.840...
%     26.521 29 32.120 36.354]);

select_range_dinei = round(16000 * [0.218 4.337 9.891 16.225 23.152 28.207...
    33.137 39.815 45.712 48.458]);
select_range_yang = round(16000 * [0.18 7.143 12.146 19.920 25.486 28.190 35.108]);

read_path = 'C:\Users\yzhan143\My Research\2016_MSR_intern\MSR_intern\results\160910\Dinei\';


for index = 1 : 5
    write_path = ['C:\Users\yzhan143\My Research\2016_MSR_intern\MSR_intern\results\160910\Dinei\', num2str(index), '_'];

    s1 = audioread([read_path, 'beamformed_', num2str(index), '.wav']);
    s1 = s1 / std(s1) / 15;
    s2 = audioread([read_path, 'mvdr_', num2str(index), '.wav']);
    s2 = s2 / std(s2) / 15;
    s3 = audioread([read_path, 'closest_', num2str(index), '.wav']);
    s3 = s3 / std(s3) / 15;

    select_range = select_range_dinei;
    for i = 1 : length(select_range) - 1
        audiowrite([write_path, 'beamformed_', num2str(i), '.wav'],...
            s1(select_range(i) : select_range(i+1)), 16000);
        audiowrite([write_path, 'mvdr_', num2str(i), '.wav'],...
            s2(select_range(i) : select_range(i+1)), 16000);
        audiowrite([write_path, 'closest_', num2str(i), '.wav'],...
            s3(select_range(i) : select_range(i+1)), 16000);
    end
end
