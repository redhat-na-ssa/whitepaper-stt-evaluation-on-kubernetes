import time
import psutil
import csv
import os
import subprocess
from datetime import datetime

# Ensure the directory exists
os.makedirs("data/metrics", exist_ok=True)

# CSV file path
csv_file_path = "data/metrics/container_metrics.csv"

# Headers for the CSV file
headers = [
    "date",
    "timestamp",
    "container name",
    "processor/gpu name",
    "core/gpu count",
    "max usage (%)",
    "max gpu temperature (C)",
    "max pwr:usage/cap (%)",
    "max vram usage (%)",
    "startup time (s)",
    "task time (s)",
    "shutdown time (s)",
    "total time (s)"
]

# Function to write the header if the file is empty
def write_csv_header():
    if not os.path.exists(csv_file_path):
        with open(csv_file_path, mode='w', newline='') as file:
            writer = csv.writer(file)
            writer.writerow(headers)

# Function to get GPU metrics
def get_gpu_metrics():
    # Placeholder for actual GPU metrics. This part will need to use a tool like nvidia-smi or other GPU-related libraries
    # Assuming the system has a GPU and we can fetch relevant metrics.
    gpu_name = "NVIDIA Tesla T4"  # Example, you can modify this depending on your environment
    core_count = psutil.cpu_count(logical=False)  # Example, real GPU data needed here
    max_usage = 50  # Placeholder, actual GPU usage should be fetched
    max_temperature = 60  # Placeholder
    max_pwr_usage = 70  # Placeholder
    max_vram_usage = 80  # Placeholder
    return gpu_name, core_count, max_usage, max_temperature, max_pwr_usage, max_vram_usage

# Function to get system timestamp
def get_timestamp():
    return datetime.now().strftime('%H:%M:%S')

# Function to monitor container start and stop events
def monitor_container(container_name):
    # Track start time
    start_time = time.time()

    # Record startup time
    startup_time = time.time() - start_time

    # Get GPU metrics at the time the container starts
    gpu_name, core_count, max_usage, max_temperature, max_pwr_usage, max_vram_usage = get_gpu_metrics()

    # Track container's task time (assuming task time is the runtime of the container)
    task_start_time = time.time()
    subprocess.run(["podman", "start", container_name])
    task_time = time.time() - task_start_time

    # Wait until the container is stopped
    subprocess.run(["podman", "wait", container_name])

    # Record shutdown time
    shutdown_time = time.time() - task_start_time
    total_time = time.time() - start_time
    
    # Prepare data for CSV
    data = [
        datetime.now().strftime('%Y-%m-%d'),
        get_timestamp(),
        container_name,
        gpu_name,
        core_count,
        max_usage,
        max_temperature,
        max_pwr_usage,
        max_vram_usage,
        startup_time,
        task_time,
        shutdown_time,
        total_time
    ]
    
    # Write the data to CSV
    with open(csv_file_path, mode='a', newline='') as file:
        writer = csv.writer(file)
        writer.writerow(data)

# Main function to continuously monitor containers
def main():
    write_csv_header()

    print("Monitoring Podman container events...")

    while True:
        # Get all running containers
        running_containers = subprocess.check_output(["podman", "ps", "--format", "{{.Names}}"]).decode().splitlines()

        for container_name in running_containers:
            print(f"Container started: {container_name}")
            monitor_container(container_name)

        time.sleep(1)  # Check every 1 seconds for new containers

if __name__ == "__main__":
    main()
