import re
import csv

input_file = r"F:\D-Drive\AST-Paper-Writing\Enhanced_log_WER\station_15-wer_station_15.txt"
output_file = r"F:\D-Drive\AST-Paper-Writing\Enhanced_log_WER\station_15-wer_station_15.csv"

wer_pattern = re.compile(r"%WER\s+([\d.]+)")
exp_pattern = re.compile(r"exp/(.*?)/wer_\d+")

results = []

last_exp = None   # store last seen exp/.../wer_xx

with open(input_file, "r") as f:
    for line in f:
        line = line.strip()

        # Case 1: line contains exp/.../wer_xx
        exp_match = exp_pattern.search(line)
        if exp_match:
            last_exp = exp_match.group(1)

        # Case 2: line contains %WER
        wer_match = wer_pattern.search(line)
        if wer_match and last_exp is not None:
            wer = wer_match.group(1)
            results.append([last_exp, wer])
            last_exp = None   # reset so it doesn't get reused incorrectly

# Write CSV
with open(output_file, "w", newline="") as csvfile:
    writer = csv.writer(csvfile)
    writer.writerow(["Experiment", "WER"])
    writer.writerows(results)

print(f"Extracted {len(results)} rows → {output_file}")
