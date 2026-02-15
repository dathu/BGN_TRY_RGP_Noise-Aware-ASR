clc;
clear;

% ================= USER SETTINGS =================
cleanDir = 'F:\D-Drive\AST-Paper-Writing\dataset\clean';
noiseDir = 'F:\D-Drive\AST-Paper-Writing\dataset\noise';
outDir   = 'F:\D-Drive\AST-Paper-Writing\dataset\noisy';

snrList = [0];                 % SNR levels
maxRetries = 10;                % max retries
attenuationList = linspace(1, 0.2, maxRetries); % adaptive scaling
% =================================================

if ~exist(outDir, 'dir')
    mkdir(outDir);
end

cleanFiles = dir(fullfile(cleanDir, '*.wav'));
noiseFiles = dir(fullfile(noiseDir, '*.wav'));

fprintf('Total clean files: %d\n', length(cleanFiles));
fprintf('Total noise files: %d\n\n', length(noiseFiles));

for i = 1:length(cleanFiles)

    % -------- READ CLEAN --------
    cleanPath = fullfile(cleanDir, cleanFiles(i).name);
    [x, fs]   = audioread(cleanPath);
    x_len     = length(x);

    % -------- PICK RANDOM NOISE --------
    noiseIdx  = randi(length(noiseFiles));
    noisePath = fullfile(noiseDir, noiseFiles(noiseIdx).name);
    [n, fs_n] = audioread(noisePath);

    if fs_n ~= fs
        n = resample(n, fs, fs_n);
    end

    [~, cleanName, ~] = fileparts(cleanFiles(i).name);
    [~, noiseName, ~] = fileparts(noiseFiles(noiseIdx).name);

    for s = 1:length(snrList)

        snr = snrList(s);
        outFileName = sprintf('%s_%s_%ddB.wav', cleanName, noiseName, snr);
        outPath = fullfile(outDir, outFileName);

        success = false;

        % ===== Adaptive Retry Loop =====
        for attempt = 1:maxRetries

            % --- Prepare Noise Segment ---
            if length(n) <= x_len
                n_rep = repmat(n, ceil((x_len+1)/length(n)), 1);
            else
                n_rep = n;
            end

            startIdx = randi(length(n_rep) - x_len);
            n_seg = n_rep(startIdx:startIdx + x_len - 1);

            % Normalize + attenuate
            n_seg = n_seg ./ max(abs(n_seg) + eps);
            n_seg = attenuationList(attempt) * n_seg;

            tempNoiseFile = fullfile(outDir, 'temp_noise.wav');
            audiowrite(tempNoiseFile, n_seg, fs);

            try
                addnoise_asl(cleanPath, tempNoiseFile, outPath, snr);
                fprintf('✔ %s | Noise: %s | SNR: %d dB\n', ...
                        cleanFiles(i).name, noiseName, snr);
                success = true;
                break;

            catch ME
                fprintf('⚠ Retry %d/%d | Atten=%.2f | %s\n', ...
                        attempt, maxRetries, attenuationList(attempt), cleanFiles(i).name);
            end
        end

        % ===== FINAL FALLBACK (MANUAL MIXING) =====
        if ~success
            fprintf('🔁 Fallback manual mix: %s\n', cleanFiles(i).name);

            % Compute noise power for desired SNR
            Px = mean(x.^2);
            Pn = mean(n_seg.^2);
            scale = sqrt(Px / (Pn * 10^(snr/10)));

            y = x + scale * n_seg;
            y = y / max(abs(y) + eps); % avoid clipping

            audiowrite(outPath, y, fs);
        end
    end
end

% Cleanup
tempFile = fullfile(outDir, 'temp_noise.wav');
if exist(tempFile, 'file')
    delete(tempFile);
end

disp('✅ ALL FILES PROCESSED — NO SKIPPING');
