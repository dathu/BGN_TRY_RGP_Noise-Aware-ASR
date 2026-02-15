import os

base_path = r"F:\D-Drive\AST-Paper-Writing\dataset\Station_Enhanced"

for folder_name in os.listdir(base_path):
    old_folder_path = os.path.join(base_path, folder_name)

    # Process only directories that start with "noisy_"
    if os.path.isdir(old_folder_path) and folder_name.startswith("noisy_"):
        new_folder_name = folder_name.replace("noisy_", "station_", 1)
        new_folder_path = os.path.join(base_path, new_folder_name)

        os.rename(old_folder_path, new_folder_path)
        print(f"Renamed: {folder_name} → {new_folder_name}")
