function [ev, Rd, keep_idx] = find_ev(e, fs, frame_len, lpc_order, Rd_old, iter, s)
% This function finds ev by peak picking
%
% Input:
% e - residual signal
% fs - sampling frequency
% frame_len - the frame length
% lpc_order - the order of LPC analysis
% Rd_old - the original glottal tightness parameter
% iter - the number of iterations in the outer loop
%
% Output:
% ev - residual with the peaks reserved
% Rd - the updated glottal tightness parameter
% keep_idx - which dimensions in e are kept

% constants to be set
ste_range = round(fs * 0.03); % the range to compute short time energy
thres = 3; % threshold above which the sample is preserved

% L-alpha norm
alpha = 0.5;
short_time_energy = (conv(hamming(ste_range), abs(e).^alpha) ...
    ./ conv(hamming(ste_range), ones(length(e), 1))) .^ (1 / alpha);
short_time_energy = short_time_energy(round(ste_range/2) : round(ste_range/2) + length(e)-1);


% compute another glottal energy
ste_range_short = round(fs * 0.002);
glottal_energy = (conv(hamming(ste_range_short), abs(s).^4) ...
    ./ conv(hamming(ste_range_short), ones(length(s), 1))) .^ (1 / 4 * 2);
glottal_energy = glottal_energy(round(ste_range_short/2) : round(ste_range_short/2) + length(e)-1);

% L-alpha norm for glottal energy
alpha2 = 0.5;
short_time_energy2 = (conv(hamming(ste_range), abs(glottal_energy).^alpha2) ...
    ./ conv(hamming(ste_range), ones(length(glottal_energy), 1))) .^ (1 / alpha2);
short_time_energy2 = short_time_energy2(round(ste_range/2) : round(ste_range/2) + length(glottal_energy)-1);

% preliminary peak picking
ev = e;
ev(e .* glottal_energy < thres * short_time_energy .* short_time_energy2...
    | short_time_energy .* short_time_energy2 < 0.1 * mean(short_time_energy .* short_time_energy2)) = 0;

% refined peak picking based on periodicity
frame_len_p = 600;
frame_shift_p = 200;
num_frames = floor((length(ev) - frame_len_p) / frame_shift_p) + 1;
keep_idx = false(length(ev), 1);
for frame_id = 1 : num_frames
    current_idx = (frame_id - 1) * frame_shift_p + (1 : frame_len_p);
    ev_normalized = ev(current_idx) ./ short_time_energy(current_idx);
    % find the pitch period using autocorrelation function
    autocorr = ifft(abs(fft(ev_normalized, frame_len_p * 2)) .^ 2);
    period_offset = round(0.002 * fs);
    [max_autocorr, period] = max(autocorr(period_offset+1 : frame_len_p));
    if max_autocorr / autocorr(1) > 0.2 % enough periodicity
        % find the group delay
        period = period + period_offset;
        [~, grp_delay] = max(sum(buffer(ev_normalized, period, 0) .^ 2, 2));
        keep_sample = [];
        period_var = round(0.2 * period); % allow some variation in period
        for search_center = grp_delay : period : frame_len_p + round(0.1 * period_var)
            search_range = max(1, search_center - period_var)...
                : min(frame_len_p - period_var, search_center + period_var);
            [~, keep_sample_temp] = max(ev_normalized(search_range));
            keep_idx(current_idx(search_range(keep_sample_temp))) = true;
        end
    end
%     ev_temp = ev(current_idx);
%     ev_temp(~keep_idx(current_idx)) = 0;
%     ev(current_idx) = ev_temp;
%     plot([keep_idx*0.01, ev]);
end
ev(~keep_idx) = 0;
keep_idx = (ev ~= 0);

% generate a model based glottal pulse
% estimate the glottal tightness and divide by frames
e_framed = buffer(e, frame_len, 0);
ev_framed = buffer(ev, frame_len, 0);
num_frames = size(e_framed, 2);

if isempty(Rd_old)
    Rd_old = 1.0 * ones(num_frames, 1);
end
Rd = Rd_old;
inc = 1e-5;

if iter == 1 % for the first time, do a more thorough gradient search
    max_iter = 12;
    step_size = 0.1;
else
    max_iter = 0;
    step_size = 0.01;
end
for frame_id = 1 : num_frames
    for iiter = 1 : max_iter
        % obtain the numerical gradient of each frame
        ev_temp1 = gen_glottal_residual(Rd(frame_id), 0.005 * fs,...
            frame_len, lpc_order, ev_framed(:, frame_id));
        sq_err1 = norm(ev_temp1 - e_framed(:, frame_id));

        Rd_temp2 = Rd(frame_id) + inc;
        ev_temp2 = gen_glottal_residual(Rd_temp2, 0.005 * fs,...
            frame_len, lpc_order, ev_framed(:, frame_id));
        sq_err2 = norm(ev_temp2 - e_framed(:, frame_id));

        grad = (sq_err2 - sq_err1) / inc;

        % make a projected gradient descent
        Rd(frame_id) = min(max(Rd(frame_id) + step_size * sign(grad), 0.3), 2.7);
    end
end
% median filter the estimated Rd
Rd = median(Rd) * ones(num_frames, 1);

% final filter
ev = gen_glottal_residual(Rd, 0.005 * fs, frame_len, lpc_order, ev);


% % match the energy
% ev = ev / norm(ev) * norm(e);

end