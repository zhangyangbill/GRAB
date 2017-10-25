function G = gen_glottal_wave(Rd, T0, frame_len)
% This function evaluates the dft of the glottal model at frequency points
% (in frequency bin) specified by pp.
%
% Input:
% Rd - the shape parameter by Fant95 model
% g - LF model parameters, which include t_e, alpha, omega_g, epsilon
% T0 - fundamental frequency in number of points
% frame_len - frame length
%
% Output:
% G - the waveform of the LF model

% Predict parameters
Ra = (-1 + 4.8 * Rd) / 100;
Rk = (22.4 + 11.8 * Rd) / 100;
Rg = 1 / (4 * ((0.11 * Rd / (0.5 + 1.2 * Rk)) - Ra) / Rk);
g.omega_g = Rg * 2 * pi / T0;
g.t_e = round((1 + Rk) * T0 / 2 / Rg);
g.epsilon = 1 / Ra / T0;
g.alpha = fzero(@glot_int, 0, [], g);

% time domain approach
G = zeros(frame_len, 1);
G(end - g.t_e + 1 : end) =...
    exp(g.alpha * (- g.t_e : -1)')...
    .* sin(g.omega_g * (g.t_e + (- g.t_e : -1)')) ...
    / (-sin(g.omega_g * g.t_e));
G = G - exp(- g.epsilon * (0 : frame_len - 1)');
% 
% G1 = T * glottal_wave;

end