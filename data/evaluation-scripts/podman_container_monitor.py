#!/usr/bin/env python3

"""
Podman Container Monitor Script

Monitors running Podman containers starting with 'whisper-', collects system,
CPU, and GPU metrics, and logs them to a CSV.

Captures:
- CPU and GPU core counts
- GPU usage, temperature, VRAM, power draw
- CPU usage and system memory
- Timing: startup, task, shutdown, and total durations

USAGE:
  nohup python3 podman_container_monitor.py &
  screen -S whisper-monitor && python3 podman_container_monitor.py
"""

import time
import psutil
import csv
import os
import subprocess
from datetime import datetime

# Ensure metrics directory exists
os.makedirs("data/metrics", exist_ok=True)

# Path to CSV log
csv_file_path = "data/metrics/container_metrics.csv"

# Updated CSV headers with separate CPU and GPU counts
headers = [
    "date",
    "timestamp",
    "container name",
    "processor/gpu name",
    "cpu core count",
    "gpu count",
    "gpu max usage (%)",
    "cpu max usage (%)",
    "max gpu temperature (C)",
    "max pwr:usage/cap (%)",
    "max vram usage (%)",
    "startup time (s)",
    "task time (s)",
    "shutdown time (s)",
    "total time (s)",
    "memory usage (MB)"
]

# Write headers if file is new or empty
def write_csv_header():
    if not os.path.exists(csv_file_path) or os.stat(csv_file_path).st_size == 0:
        with open(csv_file_path, mode='w', newline='') as file:
            writer = csv.writer(file)
            writer.writerow(headers)

# Collect GPU-related metrics via nvidia-smi
def get_gpu_metrics():
    try:
        result = subprocess.run([
            "nvidia-smi",
            "--query-gpu=name,index,utilization.gpu,temperature.gpu,power.draw,power.limit,memory.used,memory.total",
            "--format=csv,noheader,nounits"
        ], capture_output=True, text=True, check=True)

        lines = result.stdout.strip().split('\n')
        gpu_count = len(lines)                            # Total GPUs on system
        metrics = lines[0].split(', ')                    # Use first GPU's metrics
        gpu_name = metrics[0]
        gpu_max_usage = metrics[2]
        max_temperature = metrics[3]
        power_draw = float(metrics[4])
        power_limit = float(metrics[5])
        max_pwr_usage = round((power_draw / power_limit) * 100, 2)
        mem_used = float(metrics[6])
        mem_total = float(metrics[7])
        max_vram_usage = round((mem_used / mem_total) * 100, 2)

        return gpu_name, gpu_count, gpu_max_usage, max_temperature, max_pwr_usage, max_vram_usage

    except subprocess.CalledProcessError:
        return "Unknown GPU", 0, 0, 0, 0, 0

# Get timestamp as HH:MM:SS
def get_timestamp():
    return datetime.now().strftime('%H:%M:%S')

# Check if a container is currently running
def is_container_running(container_name):
    try:
        result = subprocess.run(["podman", "ps", "--format", "{{.Names}}"], capture_output=True, text=True)
        running_containers = result.stdout.strip().splitlines()
        return container_name in running_containers
    except Exception:
        return False

# Monitor loop for 'whisper-' containers
def monitor_containers():
    write_csv_header()
    seen = set()

    print("\U0001F4E1 Polling running containers every 0.1 seconds...")
    while True:
        try:
            result = subprocess.run(["podman", "ps", "--format", "{{.Names}}"], capture_output=True, text=True)
            running = result.stdout.strip().splitlines()
            for container_name in running:
                if container_name.startswith("whisper-") and container_name not in seen:
                    seen.add(container_name)
                    print(f"\U0001F4E6 Detected running container: {container_name}")
                    time.sleep(0.2)  # Let it warm up
                    capture_metrics(container_name)
        except Exception as e:
            print(f"❌ Error polling containers: {e}")
        time.sleep(0.1)

# Capture all metrics and write to CSV
def capture_metrics(container_name):
    start_time = time.time()
    startup_time = time.time() - start_time

    # Get GPU metrics
    gpu_name, gpu_count, gpu_max_usage, max_temperature, max_pwr_usage, max_vram_usage = get_gpu_metrics()

    # Start task timer while container is running
    task_start = time.time()
    while is_container_running(container_name):
        time.sleep(0.1)
    task_end = time.time()

    # Timings
    task_time = task_end - task_start
    shutdown_time = task_end - start_time
    total_time = shutdown_time

    # CPU + Memory stats
    try:
        cpu_core_count = psutil.cpu_count(logical=False)
        cpu_max_usage = psutil.cpu_percent(interval=0.1)
        mem_info = psutil.virtual_memory()
        memory_usage = round(mem_info.used / 1024 / 1024, 2)
    except Exception:
        cpu_core_count = "NA"
        cpu_max_usage = "NA"
        memory_usage = "NA"

    # Compile all data for the row
    data = [
        datetime.now().strftime('%Y-%m-%d'),
        get_timestamp(),
        container_name,
        gpu_name,
        cpu_core_count,
        gpu_count,
        gpu_max_usage,
        cpu_max_usage,
        max_temperature,
        max_pwr_usage,
        max_vram_usage,
        startup_time,
        task_time,
        shutdown_time,
        total_time,
        memory_usage
    ]

    # Write row to CSV
    with open(csv_file_path, mode='a', newline='') as file:
        writer = csv.writer(file)
        writer.writerow(data)

# Run the monitor
if __name__ == "__main__":
    monitor_containers()
