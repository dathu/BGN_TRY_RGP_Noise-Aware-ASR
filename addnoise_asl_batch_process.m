clc;
clear;

% ================= USER SETTINGS =================
cleanDir = 'F:\D-Drive\AST-Paper-Writing\dataset\clean';
noiseDir = 'F:\D-Drive\AST-Paper-Writing\dataset\noise';
outDir   = 'F:\D-Drive\AST-Paper-Writing\dataset\noisy';

snrList = [-5];   % SNR levels in dB -10 -5 0 5 10
maxRetries = 10;              % retries for ASL overflow
% =================================================

if ~exist(outDir, 'dir')
    mkdir(outDir);
end

cleanFiles = dir(fullfile(cleanDir, '*.wav'));
noiseFiles = dir(fullfile(noiseDir, '*.wav'));

fprintf('Total clean files: %d\n', length(cleanFiles));
fprintf('Total noise files: %d\n\n', length(noiseFiles));

for i = 1:length(cleanFiles)

    % -------- READ CLEAN SPEECH --------
    cleanPath = fullfile(cleanDir, cleanFiles(i).name);
    [x, fs]   = audioread(cleanPath);
    x_len     = length(x);

    % -------- PICK RANDOM NOISE FILE --------
    noiseIdx  = randi(length(noiseFiles));
    noisePath = fullfile(noiseDir, noiseFiles(noiseIdx).name);
    [n, fs_n] = audioread(noisePath);

    % Sampling rate check
    if fs_n ~= fs
        n = resample(n, fs, fs_n);
    end

    [~, cleanName, ~] = fileparts(cleanFiles(i).name);
    [~, noiseName, ~] = fileparts(noiseFiles(noiseIdx).name);

    % -------- PROCESS EACH SNR --------
    for s = 1:length(snrList)

        snr = snrList(s);
        success = false;

        for attempt = 1:maxRetries

            % ===== SAFE NOISE PREPARATION =====
            noise_len = length(n);

            % Ensure noise strictly longer than speech
            if noise_len <= x_len
                n_rep = repmat(n, ceil((x_len+1)/noise_len), 1);
            else
                n_rep = n;
            end

            % Random noise segment (CRITICAL)
            startIdx = randi(length(n_rep) - (x_len+1) + 1);
            n_seg = n_rep(startIdx : startIdx + x_len);

            % Normalize noise to avoid ASL overflow
            n_seg = n_seg ./ max(abs(n_seg) + eps);

            % Temporary noise file
            tempNoiseFile = fullfile(outDir, 'temp_noise.wav');
            audiowrite(tempNoiseFile, n_seg, fs);
            % =================================

            try
                outFileName = sprintf('%s_%s_%ddB.wav', ...
                                      cleanName, noiseName, snr);
                outPath = fullfile(outDir, outFileName);

                % ---- CALL LEGACY ASL FUNCTION ----
                addnoise_asl(cleanPath, tempNoiseFile, outPath, snr);

                fprintf('✔ %s | Noise: %s | SNR: %d dB\n', ...
                        cleanFiles(i).name, noiseName, snr);

                success = true;
                break;  % exit retry loop

            catch ME
                if contains(ME.message, 'Overflow')
                    fprintf('⚠ Overflow retry %d/%d : %s (SNR %d dB)\n', ...
                            attempt, maxRetries, cleanFiles(i).name, snr);
                else
                    rethrow(ME); % unknown error
                end
            end
        end

        if ~success
            fprintf('❌ SKIPPED: %s | Noise: %s | SNR: %d dB\n', ...
                    cleanFiles(i).name, noiseName, snr);
        end
    end
end

% Cleanup
if exist(fullfile(outDir, 'temp_noise.wav'), 'file')
    delete(fullfile(outDir, 'temp_noise.wav'));
end

disp('✅ Batch noise addition completed safely.');
