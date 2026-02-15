import os
import numpy as np
import soundfile as sf
from tqdm import tqdm

# ================= USER SETTINGS =================
CLEAN_DIR = r"F:\D-Drive\AST-Paper-Writing\noise-add-python-code\dataset\clean"
NOISE_DIR = r"F:\D-Drive\AST-Paper-Writing\noise-add-python-code\dataset\noise"
OUT_DIR   = r"F:\D-Drive\AST-Paper-Writing\noise-add-python-code\dataset\noisy"

SNR_LIST = [-5]
SILENCE_THRESH = 0.01
# =================================================

os.makedirs(OUT_DIR, exist_ok=True)

clean_files = [f for f in os.listdir(CLEAN_DIR) if f.lower().endswith(".wav")]
noise_files = [f for f in os.listdir(NOISE_DIR) if f.lower().endswith(".wav")]

if len(noise_files) == 0:
    raise RuntimeError("❌ No noise WAV files found!")

print(f"Clean files: {len(clean_files)}")
print(f"Noise files: {len(noise_files)}\n")

# ------------------------------------------------
def active_rms(signal, thresh):
    energy = signal ** 2
    mask = energy > thresh * np.max(energy)
    if np.sum(mask) == 0:
        return np.sqrt(np.mean(energy))
    return np.sqrt(np.mean(energy[mask]))

# ------------------------------------------------
for clean_file in tqdm(clean_files, desc="Processing clean files"):

    clean_path = os.path.join(CLEAN_DIR, clean_file)
    clean, sr = sf.read(clean_path)
    if clean.ndim > 1:
        clean = np.mean(clean, axis=1)

    x_len = len(clean)

    noise_file = np.random.choice(noise_files)
    noise_path = os.path.join(NOISE_DIR, noise_file)
    noise, sr_n = sf.read(noise_path)
    if noise.ndim > 1:
        noise = np.mean(noise, axis=1)

    # Ensure noise longer than speech
    if len(noise) <= x_len:
        reps = int(np.ceil((x_len + 1) / len(noise)))
        noise = np.tile(noise, reps)

    # Random noise segment
    start = np.random.randint(0, len(noise) - x_len)
    noise_seg = noise[start:start + x_len]

    # Normalize noise
    noise_seg = noise_seg / (np.max(np.abs(noise_seg)) + 1e-12)

    speech_rms = active_rms(clean, SILENCE_THRESH)

    for snr in SNR_LIST:
        noise_rms = np.sqrt(np.mean(noise_seg ** 2))
        scale = speech_rms / (noise_rms * (10 ** (snr / 20)))

        noisy = clean + scale * noise_seg
        noisy = noisy / (np.max(np.abs(noisy)) + 1e-12)

        clean_name = os.path.splitext(clean_file)[0]
        noise_name = os.path.splitext(noise_file)[0]
        out_name = f"{clean_name}_{noise_name}_{snr}dB.wav"
        out_path = os.path.join(OUT_DIR, out_name)

        sf.write(out_path, noisy, sr)

print("\n✅ Batch noise addition completed successfully.")
