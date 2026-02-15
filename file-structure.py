import os

# Define the base path
base_path = r"C:\Users\raghudathesh.gp\Desktop\Airflowdata"

# Define the lists for noise types, folder types, and SNR levels
noise_types = ['airport', 'babble', 'station', 'restaurant']
folder_types = ['test', 'train']
snr_levels = ['0dB', '5dB', '10dB', '15dB']

# Create the folders for all combinations
for x in noise_types:
    for w in folder_types:
        for y in snr_levels:
            folder_name = f"noisy_{x}_{w}_{y}"
            full_path = os.path.join(base_path, folder_name)
            if not os.path.exists(full_path):
                os.makedirs(full_path)
            else:
                print(f"Folder '{folder_name}' already exists.")