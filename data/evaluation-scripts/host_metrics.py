import csv
import os
import time
import subprocess
from datetime import datetime

def get_pod_info():
    try:
        pod_info = subprocess.check_output(['podman', 'ps', '--format', '{{.Names}}']).decode().strip()
        pod_name = pod_info if pod_info else 'No Pod'
    except subprocess.CalledProcessError:
        pod_name = 'Error Retrieving Pod'
    return pod_name

def get_cpu_info():
    try:
        cpu_info = subprocess.check_output(['lscpu']).decode().strip().split('\n')
        cpu_model = next((line.split(':')[1].strip() for line in cpu_info if 'Model name' in line), 'Unknown CPU')
        cpu_cores = next((line.split(':')[1].strip() for line in cpu_info if 'CPU(s)' in line), 'Unknown')
    except subprocess.CalledProcessError:
        cpu_model, cpu_cores = 'Error Retrieving CPU', 'Error'
    return cpu_model, cpu_cores

def get_gpu_info():
    try:
        gpu_data = subprocess.check_output([
            'nvidia-smi',
            '--query-gpu=name,count,utilization.gpu,temperature.gpu,power.draw,power.limit,memory.used,memory.total',
            '--format=csv,noheader']).decode().strip()
        if gpu_data:
            gpu_info = [line.split(', ') for line in gpu_data.split('\n')]
            gpu_name = gpu_info[0][0]
            gpu_count = len(gpu_info)
            max_utilization = max(int(gpu[2].replace('%', '')) for gpu in gpu_info)
            max_temperature = max(int(gpu[3].replace('C', '').strip()) for gpu in gpu_info)
            max_power_usage = max(float(gpu[4].replace('W', '').strip()) / float(gpu[5].replace('W', '').strip()) * 100 for gpu in gpu_info)
            max_vram_usage = max(float(gpu[6].replace('MiB', '').strip()) / float(gpu[7].replace('MiB', '').strip()) * 100 for gpu in gpu_info)
        else:
            raise FileNotFoundError
    except (subprocess.CalledProcessError, FileNotFoundError):
        gpu_name, gpu_count, max_utilization, max_temperature, max_power_usage, max_vram_usage = get_cpu_info() + (None, None, None)
    return gpu_name, gpu_count, max_utilization, max_temperature, max_power_usage, max_vram_usage

def write_timing_to_csv(start_time, task_time, shutdown_time, pod_name):
    output_dir = 'data/output'
    os.makedirs(output_dir, exist_ok=True)
    file_path = os.path.join(output_dir, 'pod_timing.csv')

    file_exists = os.path.isfile(file_path)

    with open(file_path, mode='a', newline='') as file:
        writer = csv.writer(file)
        if not file_exists:
            writer.writerow(['date', 'timestamp', 'pod name', 'startup time (s)', 'task time (s)', 'shutdown time (s)', 'total time (s)'])
        now = datetime.now()
        total_time = start_time + task_time + shutdown_time
        writer.writerow([now.strftime("%Y-%m-%d"), now.strftime("%H%M%S"), pod_name, f"{start_time:.3f}", f"{task_time:.3f}", f"{shutdown_time:.3f}", f"{total_time:.3f}"])

def run_container_and_measure(image, task_command):
    start_all = time.time()

    # Start container
    start = time.time()
    subprocess.run(['podman', 'run', '-d', '--name', 'timed-container', image, 'sleep', '60'], check=True)
    startup_time = time.time() - start

    # Execute task inside container
    start = time.time()
    subprocess.run(['podman', 'exec', 'timed-container'] + task_command, check=True)
    task_time = time.time() - start

    # Stop and remove container
    start = time.time()
    subprocess.run(['podman', 'rm', '-f', 'timed-container'], check=True)
    shutdown_time = time.time() - start

    # Get pod name just for reference
    pod_name = get_pod_info()

    write_timing_to_csv(startup_time, task_time, shutdown_time, pod_name)

    return {
        'startup_time': startup_time,
        'task_time': task_time,
        'shutdown_time': shutdown_time,
        'total_time': time.time() - start_all
    }

# Example usage:
if __name__ == '__main__':
    image_name = 'python:3.11-slim'
    task = ['python3', '-c', 'print("Hello from inside container")']
    times = run_container_and_measure(image_name, task)
    print("Timing:", times)
