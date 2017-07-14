function [s_short, convert_mat] = long2short_spect2(X_long, len_short)
% This function converts long spectrum to short WAVEFORM time domain
% windowing.
%
% Input:
% X_long - the long spectrum, each column is the long half spectrum
% len_short - the length of the short spectrum (# unique elements)
% window - the function handle of the window function for the short frame.
%
% Output:
% s_short - the short waveform, each column is the short frame
% convert_mat - the matrix that converts full long spectrum to X_short

% set persistent variables to improve computational efficiency
persistent L_SHORT
persistent L_LONG
persistent C_MAT

len_long = size(X_long, 1);

% convert to time domain
s = real(ifft([X_long; conj(X_long(end-1 : -1 : 2, :))]));

% window the time domain signal
len_window = 2 * (len_short - 1);
len_frame =  2 * (len_long - 1);

% position the window
window_start_idx = round((len_frame - len_window) / 2);
s_short = s(window_start_idx+1 : window_start_idx+len_window, :);

% compute the conversion matrix
% initiliaze persistent variables
if nargout == 2
    if isempty(L_SHORT) || isempty(L_LONG) || isempty(C_MAT)...
            || L_SHORT ~= len_short || L_LONG ~= len_long 
        L_SHORT = len_short;
        L_LONG = len_long;
        
        % matrix that converts to time domain
        idft_mat = dftmtx(len_frame)' / len_window / 2;
        C_MAT = idft_mat(window_start_idx+1 : window_start_idx+len_window, :);
    end
    convert_mat = C_MAT;
end

end