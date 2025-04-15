#!/usr/bin/env python3

"""
Podman Container Monitor Script

This script continuously polls running Podman containers every 0.1 seconds.
When a container with a name starting with 'whisper-' is detected, it records
system and GPU usage metrics and appends them to a CSV file.

Metrics captured:
- GPU name, temperature, utilization
- CPU and memory usage
- Power usage as percentage of GPU capacity
- VRAM usage as percentage
- Timestamps and timing metadata

USAGE:
Run this script in the background:
  nohup python3 podman_container_monitor.py &

Or from a screen session:
  screen -S whisper-monitor
  python3 podman_container_monitor.py
  # Press Ctrl+A, then D to detach

Output is written to:
  data/metrics/container_metrics.csv
"""

import time
import psutil
import csv
import os
import subprocess
from datetime import datetime

# Ensure the metrics directory exists
os.makedirs("data/metrics", exist_ok=True)

# Path to the CSV file where metrics will be stored
csv_file_path = "data/metrics/container_metrics.csv"

# CSV headers
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
    "total time (s)",
    "cpu usage (%)",
    "memory usage (MB)"
]

# Write CSV header if the file doesn't exist or is empty
def write_csv_header():
    if not os.path.exists(csv_file_path) or os.stat(csv_file_path).st_size == 0:
        with open(csv_file_path, mode='w', newline='') as file:
            writer = csv.writer(file)
            writer.writerow(headers)

# Get current GPU metrics using nvidia-smi
# Returns details such as GPU name, core count, usage, temperature, power usage, VRAM usage
def get_gpu_metrics():
    try:
        result = subprocess.run([
            "nvidia-smi",
            "--query-gpu=name,index,utilization.gpu,temperature.gpu,power.draw,power.limit,memory.used,memory.total",
            "--format=csv,noheader,nounits"
        ], capture_output=True, text=True, check=True)

        metrics = result.stdout.strip().split('\n')[0].split(', ')
        gpu_name = metrics[0]                                 # GPU model name
        core_count = psutil.cpu_count(logical=False)         # Number of physical CPU cores
        max_usage = metrics[2]                               # GPU utilization (%)
        max_temperature = metrics[3]                         # GPU temperature in Celsius
        power_draw = float(metrics[4])
        power_limit = float(metrics[5])
        max_pwr_usage = round((power_draw / power_limit) * 100, 2)  # Power usage as percentage of cap
        mem_used = float(metrics[6])
        mem_total = float(metrics[7])
        max_vram_usage = round((mem_used / mem_total) * 100, 2)     # VRAM usage as percentage

        return gpu_name, core_count, max_usage, max_temperature, max_pwr_usage, max_vram_usage

    except subprocess.CalledProcessError:
        return "Unknown GPU", 0, 0, 0, 0, 0

# Get formatted time string for current timestamp
def get_timestamp():
    return datetime.now().strftime('%H:%M:%S')

# Poll Podman containers every 0.1 seconds and capture metrics for containers starting with 'whisper-'
def monitor_containers():
    write_csv_header()
    seen = set()  # Track already seen container names to avoid duplicate logging
    print("\U0001F4E1 Polling running containers every 0.1 seconds...")
    while True:
        try:
            result = subprocess.run(["podman", "ps", "--format", "{{.Names}}"], capture_output=True, text=True)
            running = result.stdout.strip().splitlines()
            for container_name in running:
                # Only monitor new containers starting with 'whisper-'
                if container_name.startswith("whisper-") and container_name not in seen:
                    seen.add(container_name)
                    print(f"\U0001F4E6 Detected running container: {container_name}")
                    time.sleep(0.2)  # Short delay to allow container startup
                    capture_metrics(container_name)
        except Exception as e:
            print(f"❌ Error polling containers: {e}")
        time.sleep(0.1)

# Collect and log metrics for the given container
# Includes CPU, memory, GPU usage, and timing metrics
def capture_metrics(container_name):
    start_time = time.time()
    startup_time = time.time() - start_time

    # Retrieve GPU metrics
    gpu_name, core_count, max_usage, max_temperature, max_pwr_usage, max_vram_usage = get_gpu_metrics()

    shutdown_time = time.time() - start_time
    total_time = shutdown_time

    try:
        cpu_usage = psutil.cpu_percent(interval=0.1)  # CPU usage sampled over 0.1 seconds
        mem_info = psutil.virtual_memory()
        memory_usage = round(mem_info.used / 1024 / 1024, 2)  # Convert from bytes to MB
    except Exception:
        cpu_usage = "NA"
        memory_usage = "NA"

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
        0,  # Placeholder for task_time
        shutdown_time,
        total_time,
        cpu_usage,
        memory_usage
    ]

    # Append row to the CSV file
    with open(csv_file_path, mode='a', newline='') as file:
        writer = csv.writer(file)
        writer.writerow(data)

if __name__ == "__main__":
    monitor_containers()