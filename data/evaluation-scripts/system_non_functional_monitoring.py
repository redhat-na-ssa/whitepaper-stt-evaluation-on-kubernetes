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
  nohup python3 system_non_functional_monitoring.py &
  screen -S whisper-monitor && python3 system_non_functional_monitoring.py
"""

import time
import psutil
import csv
import os
import subprocess
from datetime import datetime

# Ensure output directory exists
os.makedirs("data/metrics", exist_ok=True)
csv_file_path = "data/metrics/container_metrics.csv"

# CSV headers grouped by section
headers = [
    # Container Info
    "date",
    "timestamp",
    "container name",

    # CPU Info
    "cpu name",
    "cpu core count",
    "cpu max usage (%)",
    "memory usage (MB)",

    # GPU Info
    "gpu index",
    "gpu name",
    "gpu count",
    "gpu max usage (%)",
    "gpu temperature (C)",
    "gpu pwr:usage/cap (%)",
    "gpu vram usage (%)",

    # Time Info
    "startup time (s)",
    "task time (s)",
    "shutdown time (s)",
    "total time (s)"
]

def write_csv_header():
    """Write header to CSV if it doesn't already exist."""
    if not os.path.exists(csv_file_path) or os.stat(csv_file_path).st_size == 0:
        with open(csv_file_path, mode='w', newline='') as file:
            writer = csv.writer(file)
            writer.writerow(headers)

def get_cpu_name():
    """Get human-readable CPU model name."""
    try:
        result = subprocess.run(["lscpu"], capture_output=True, text=True, check=True)
        for line in result.stdout.splitlines():
            if "Model name:" in line:
                return line.split(":", 1)[1].strip()
    except Exception:
        try:
            with open("/proc/cpuinfo", "r") as f:
                for line in f:
                    if line.lower().startswith("model name"):
                        return line.split(":", 1)[1].strip()
        except:
            pass
    return "Unknown CPU"

def get_per_gpu_metrics():
    """Retrieve metrics for each GPU using nvidia-smi."""
    try:
        result = subprocess.run([
            "nvidia-smi",
            "--query-gpu=index,name,utilization.gpu,temperature.gpu,power.draw,power.limit,memory.used,memory.total",
            "--format=csv,noheader,nounits"
        ], capture_output=True, text=True, check=True)

        lines = result.stdout.strip().split('\n')
        gpu_metrics = []
        for line in lines:
            index, name, util, temp, pwr_draw, pwr_limit, mem_used, mem_total = line.split(', ')
            pwr_pct = round((float(pwr_draw) / float(pwr_limit)) * 100, 2)
            vram_pct = round((float(mem_used) / float(mem_total)) * 100, 2)
            gpu_metrics.append({
                "index": index,
                "name": name,
                "util": util,
                "temp": temp,
                "pwr_pct": pwr_pct,
                "vram_pct": vram_pct
            })
        return gpu_metrics
    except subprocess.CalledProcessError:
        return []

def get_timestamp():
    """Return HH:MM:SS string."""
    return datetime.now().strftime('%H:%M:%S')

def is_container_running(container_name):
    """Check if a specific Podman container is currently running."""
    try:
        result = subprocess.run(["podman", "ps", "--format", "{{.Names}}"], capture_output=True, text=True)
        return container_name in result.stdout.strip().splitlines()
    except Exception:
        return False

def monitor_containers():
    """Continuously monitor and log container metrics."""
    write_csv_header()
    seen = set()

    print("Polling running containers every 0.1 seconds...")
    while True:
        try:
            result = subprocess.run(["podman", "ps", "--format", "{{.Names}}"], capture_output=True, text=True)
            for container_name in result.stdout.strip().splitlines():
                if container_name.startswith("whisper-") and container_name not in seen:
                    seen.add(container_name)
                    print(f"Detected container: {container_name}")
                    time.sleep(0.2)
                    capture_metrics(container_name)
        except Exception as e:
            print(f"Error: {e}")
        time.sleep(0.1)

def capture_metrics(container_name):
    """Capture and write system + GPU metrics for a running container."""
    start_time = time.time()
    startup_time = time.time() - start_time

    # Track task execution time
    task_start = time.time()
    while is_container_running(container_name):
        time.sleep(0.1)
    task_end = time.time()

    task_time = task_end - task_start
    shutdown_time = task_end - start_time
    total_time = shutdown_time

    # CPU and memory stats
    try:
        cpu_name = get_cpu_name()
        cpu_core_count = psutil.cpu_count(logical=False)
        cpu_max_usage = psutil.cpu_percent(interval=0.1)
        mem_info = psutil.virtual_memory()
        memory_usage = round(mem_info.used / 1024 / 1024, 2)
    except Exception:
        cpu_name = "Unknown"
        cpu_core_count = "NA"
        cpu_max_usage = "NA"
        memory_usage = "NA"

    # GPU stats (one row per GPU)
    gpu_metrics_list = get_per_gpu_metrics()
    gpu_count = len(gpu_metrics_list)

    with open(csv_file_path, mode='a', newline='') as file:
        writer = csv.writer(file)
        for gpu in gpu_metrics_list:
            row = [
                # Container Info
                datetime.now().strftime('%Y-%m-%d'),
                get_timestamp(),
                container_name,

                # CPU Info
                cpu_name,
                cpu_core_count,
                cpu_max_usage,
                memory_usage,

                # GPU Info
                gpu["index"],
                gpu["name"],
                gpu_count,
                gpu["util"],
                gpu["temp"],
                gpu["pwr_pct"],
                gpu["vram_pct"],

                # Timing Info
                startup_time,
                task_time,
                shutdown_time,
                total_time
            ]
            writer.writerow(row)

if __name__ == "__main__":
    monitor_containers()
