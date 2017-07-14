function [X_short, convert_mat] = long2short_spect(X_long, len_short, window)
% This function converts long spectrum to short spectrum time domain
% windowing.
%
% Input:
% X_long - the long spectrum, each column is the long half spectrum
% len_short - the length of the short spectrum (# unique elements)
% window - the function handle of the window function for the short frame.
%
% Output:
% X_short - the short spectrum, each column is the short half spectrum
% convert_mat - the matrix that converts full long spectrum to X_short

% set persistent variables to improve computational efficiency
persistent L_SHORT
persistent L_LONG
persistent C_MAT
persistent WINDOW

len_long = size(X_long, 1);

% convert to time domain
s = ifft([X_long; conj(X_long(end-1 : -1 : 2, :))]);

% window the time domain signal
len_window = 2 * (len_short - 1);
len_frame =  2 * (len_long - 1);
if isa(window, 'function_handle')
    window = window(len_window);
end
% position the window
window_start_idx = round((len_frame - len_window) / 2);
s_short = bsxfun(@times, s(window_start_idx+1 : window_start_idx+len_window, :), window);

% convert back into frequency domain
X_short = fft(s_short);
X_short = X_short(1 : len_short, :);

% compute the conversion matrix
% initiliaze persistent variables
if nargout == 2
    if isempty(L_SHORT) || isempty(L_LONG) || isempty(C_MAT) || isempty(WINDOW)...
            || L_SHORT ~= len_short || L_LONG ~= len_long || any(WINDOW ~= window) 
        L_SHORT = len_short;
        L_LONG = len_long;
        WINDOW = window;
        
        % matrix that converts to time domain
        idft_mat = dftmtx(len_frame)' / len_window;
        window_idft_mat = bsxfun(@times,...
            idft_mat(window_start_idx+1 : window_start_idx+len_window, :), window);
        C_MAT = fft(window_idft_mat);
        C_MAT = C_MAT(1 : len_short, :);
    end
    convert_mat = C_MAT;
end

end