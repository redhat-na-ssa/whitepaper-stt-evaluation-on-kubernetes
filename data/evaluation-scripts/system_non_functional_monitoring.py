#!/usr/bin/env python3

"""
System Monitor Script for Podman Whisper Containers

Continuously monitors Podman containers that begin with 'whisper-', capturing system-level performance metrics
such as CPU, GPU, memory usage, and lifecycle timings. Output is written to CSV for analysis.

Usage:
    nohup python3 system_non_functional_monitoring.py &
    screen -S whisper-monitor && python3 system_non_functional_monitoring.py
"""

import time
import psutil
import csv
import os
import subprocess
from datetime import datetime

# ======================= Ensure Metrics Directory is Writable ==================
#os.makedirs("data/metrics", exist_ok=True)
#csv_file_path = "data/metrics/system_non_functional_metrics.csv"

instance = os.getenv("INSTANCE", "unknown_instance")
flavor = os.getenv("FLAVOR", "unknown_flavor")

csv_file_path = f"data/metrics/{instance}/{flavor}"
os.makedirs(csv_file_path, exist_ok=True)

output_file = os.path.join(csv_file_path, "system_non_functional_metrics.csv")

# ============================= Define CSV Headers ==============================
# Define CSV headers to organize metrics
headers = [
    # Container identification
    "date",
    "timestamp",
    "container name",

    # CPU metrics
    "cpu name",
    "cpu core count",
    "cpu max usage (%)",
    "memory usage (MB)",

    # GPU metrics (1 row per GPU)
    "gpu index",
    "gpu name",
    "gpu count",
    "gpu max usage (%)",
    "gpu temperature (C)",
    "gpu pwr:usage/cap (%)",
    "gpu vram usage (%)",

    # Timing data
    "startup time (s)",
    "task time (s)",
    "shutdown time (s)",
    "total time (s)"
]

# ============================ CSV Header Setup =================================
def write_csv_header():
    """Write CSV headers if the file is empty or missing."""
    if not os.path.exists(csv_file_path) or os.stat(csv_file_path).st_size == 0:
        with open(csv_file_path, mode='w', newline='') as file:
            writer = csv.writer(file)
            writer.writerow(headers)

# ============================== CPU Detection ==================================
def get_cpu_name():
    """Return the CPU model string (cross-platform fallback)."""
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

# ============================== GPU Metrics Collection ==========================
def get_per_gpu_metrics():
    """Collect per-GPU utilization, power, and memory statistics."""
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

# ============================ Timestamp Generator ==============================
def get_timestamp():
    """Return the current time in HH:MM:SS format."""
    return datetime.now().strftime('%H:%M:%S')

# ========================= Container Status Check ==============================
def is_container_running(container_name):
    """Return True if the given container is currently running."""
    try:
        result = subprocess.run(["podman", "ps", "--format", "{{.Names}}"], capture_output=True, text=True)
        return container_name in result.stdout.strip().splitlines()
    except Exception:
        return False

# ============================= Monitor Whisper Jobs ============================
def monitor_containers():
    """Poll podman for whisper-* containers and monitor them until exit."""
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
                    time.sleep(0.2)  # Small buffer before collecting metrics
                    capture_metrics(container_name)
        except Exception as e:
            print(f"Error: {e}")
        time.sleep(0.1)

# ========================== Collect & Write Metrics ============================
def capture_metrics(container_name):
    """Track system metrics and timings while a whisper container is running."""
    start_time = time.time()
    startup_time = time.time() - start_time  # Effectively near-zero since start_time is immediate

    # ====================== Container Task Duration Tracking =====================
    task_start = time.time()
    while is_container_running(container_name):
        time.sleep(0.1)
    task_end = time.time()

    task_time = task_end - task_start
    shutdown_time = task_end - start_time
    total_time = shutdown_time

    # ========================== CPU & Memory Metrics ============================
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

    # ============================ GPU Metrics Logging ============================
    gpu_metrics_list = get_per_gpu_metrics()
    gpu_count = len(gpu_metrics_list)

    # ========================= CSV Row Writing per GPU ===========================
    with open(csv_file_path, mode='a', newline='') as file:
        writer = csv.writer(file)
        for gpu in gpu_metrics_list:
            row = [
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

# ================================ Entrypoint ===================================
if __name__ == "__main__":
    monitor_containers()

