function enhanced_signal = mss_smpo(x, Srate, method)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MSS-SMPO: Soft Masking using Posterior SNR uncertainty
%
% Inputs:
%   x       : noisy speech signal (Nx1)
%   Srate   : sampling frequency (Hz)
%   method  : noise estimation method (default: 'mcra')
%
% Output:
%   enhanced_signal : enhanced speech signal
%
% Ref:
%   Lu, Y. and Loizou, P. (2011), IEEE TASLP
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if nargin < 3
    method = 'mcra';
end

x = x(:);   % ensure column vector

%% ================== PARAMETERS ==================
len = floor(20*Srate/1000);
if rem(len,2)==1
    len = len + 1;
end

PERC = 50;
len1 = floor(len*PERC/100);
len2 = len - len1;

win = hanning(len);
U   = norm(win);

nFFT  = len;
nFFT2 = len/2;

%% ================== NOISE INITIALIZATION ==================
noise_mean = zeros(nFFT,1);
j   = 1;
NIS = 8;

for k = 1:NIS
    noise_mean = noise_mean + abs(fft(win.*x(j:j+len-1), nFFT)/U);
    j = j + len;
end

noise_mu  = noise_mean/NIS;
noise_mu2 = noise_mu.^2;

%% ================== PROCESSING ==================
k = 1;
x_old   = zeros(len1,1);
Nframes = floor(length(x)/len2)-1;
xfinal  = zeros(Nframes*len2,1);

ksi     = 0;
ksi_old = zeros(len,1);

for n = 1:Nframes

    insign = win .* x(k:k+len-1);
    spec   = fft(insign,nFFT)/U;

    sig  = abs(spec);
    sig2 = sig.^2;

    sig2      = sig2(1:nFFT2+1);
    noise_mu2 = noise_mu2(1:nFFT2+1);

    % ---- Noise Estimation ----
    noise_mu2 = [noise_mu2; noise_mu2(end-1:-1:2)];
    sig2      = [sig2; sig2(end-1:-1:2)];

    if n < NIS
        parameters = initialise_parameters_book(noise_mu2, Srate, method);
    else
        parameters = noise_estimation_book(sig2, method, parameters);
        noise_mu2  = parameters.noise_ps;
    end

    noise_mu2 = noise_mu2(1:nFFT2+1);
    sig2      = sig2(1:nFFT2+1);

    % ---- SNR Estimation ----
    gammak = min(sig2 ./ noise_mu2, 1000);
    aa = 0.90;

    if n == 1
        ksi = (1-aa) * max(gammak-1,0);
    else
        ksi = max(aa*Xk_prev./noise_mu2_old + (1-aa)*(gammak-1), 0.0126);
    end

    noise_mu2_old = noise_mu2;

    % ---- Gain Function (SMPO) ----
    ksi = max(ksi,0.0025);

    delta = 0.0002;
    theta = 1;

    hw = ones(size(ksi));
    vu = zeros(size(ksi));

    idx = find(abs(ksi-1) > delta);
    vu(idx) = (1-ksi(idx))./ksi(idx) .* gammak(idx);
    P = (exp(vu(idx)/(theta+1)) - 1) ./ (exp(vu(idx)) - 1);
    hw(idx) = P + (1-P)*0.01;

    idx = find(abs(ksi-1) <= delta);
    P = 1/(theta+1);
    hw(idx) = P + (1-P)*0.01;

    hw = min(hw,1);
    hw = hw.^0.5;
    hw = max(hw, sqrt(10^(-24/10)));

    % ---- Enhancement ----
    enh_sig = sig(1:nFFT2+1) .* hw;
    Xk_prev = enh_sig.^2;

    % ---- Reconstruction ----
    hw_full = [hw; hw(end-1:-1:2)];
    xi_w = real(ifft(hw_full .* spec)) * U;

    xfinal(k:k+len2-1) = x_old + xi_w(1:len1);
    x_old = xi_w(len1+1:len);

    k = k + len2;
end

%% ================== OUTPUT ==================
enhanced_signal = xfinal;
enhanced_signal = enhanced_signal ./ max(abs(enhanced_signal) + eps);

end
