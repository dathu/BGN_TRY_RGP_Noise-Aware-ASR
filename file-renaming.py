import os

# Path to your folder
folder_path = r"F:\D-Drive\AST-Paper-Writing\dataset\noisy_restaurant_train_15"   # change if needed
#folder_path = r"F:\D-Drive\AST-Paper-Writing\dataset\noisy_test_15"

# String to remove from filenames
remove_str = "_restaurant_15dB"

for filename in os.listdir(folder_path):
    if filename.endswith(".wav") and remove_str in filename:
        old_path = os.path.join(folder_path, filename)
        new_filename = filename.replace(remove_str, "")
        new_path = os.path.join(folder_path, new_filename)

        os.rename(old_path, new_path)
        print(f"Renamed: {filename} -> {new_filename}")

print("Renaming completed.")
