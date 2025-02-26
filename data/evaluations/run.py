# USAGE 
# python run.py audio-samples/jfk-audio-inaugural-address-20-january-1961.mp3 tiny.en

import time
import subprocess
import csv
import psutil
import argparse

def track_whisper_time(audio_file, model_size):
    command = [
        "time", "whisper", audio_file,
        "--model", model_size
    ]
    
    timestamp = time.strftime('%Y-%m-%d_%H-%M-%S')
    output_file = f"output/whisper-{model_size}-ubuntu-transcript-{timestamp}.txt"
    csv_file = "output/whisper_execution_times.csv"
    
    # Start tracking resource usage
    process = psutil.Process()
    start_time = time.time()
    with open(output_file, "w") as outfile:
        subprocess.run(command, stdout=outfile, stderr=subprocess.STDOUT)
    end_time = time.time()
    
    elapsed_time = end_time - start_time
    max_cpu = process.cpu_percent(interval=1)
    max_memory = process.memory_info().rss / (1024 * 1024)  # Convert to MB
    
    print(f"Execution Time: {elapsed_time:.2f} seconds")
    print(f"Max CPU Usage: {max_cpu:.2f}%")
    print(f"Max Memory Usage: {max_memory:.2f} MB")
    print(f"Output saved to: {output_file}")
    
    # Write results to CSV
    with open(csv_file, "a", newline='') as csvfile:
        csv_writer = csv.writer(csvfile)
        csv_writer.writerow([timestamp, audio_file, model_size, elapsed_time, max_cpu, max_memory, output_file])
    
    print(f"Execution time and resource usage logged in: {csv_file}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Track execution time and resource usage of Whisper transcription.")
    parser.add_argument("audio_file", type=str, help="Path to the audio file for transcription.")
    parser.add_argument("model_size", type=str, help="Size of the Whisper model to use (e.g., tiny.en, base, small, medium, large).")
    args = parser.parse_args()
    
    track_whisper_time(args.audio_file, args.model_size)
