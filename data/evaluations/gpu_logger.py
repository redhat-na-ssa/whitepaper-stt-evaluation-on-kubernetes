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
        gpu_data = subprocess.check_output(['nvidia-smi', '--query-gpu=name,count,utilization.gpu,temperature.gpu,power.draw,power.limit,memory.used,memory.total', '--format=csv,noheader']).decode().strip()
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

def write_to_csv(pod_name, gpu_name, gpu_count, max_utilization, max_temperature, max_power_usage, max_vram_usage):
    output_dir = 'data/output'
    os.makedirs(output_dir, exist_ok=True)
    file_path = os.path.join(output_dir, 'pod_host_usage.csv')
    
    file_exists = os.path.isfile(file_path)
    
    with open(file_path, mode='a', newline='') as file:
        writer = csv.writer(file)
        if not file_exists:
            writer.writerow(['Date', 'Pod Name', 'Processor/GPU Name', 'Core/GPU Count', 'Max Usage (%)', 'Max GPU Temperature (C)', 'Max Pwr:Usage/Cap (%)', 'Max VRAM Usage (%)'])
        writer.writerow([datetime.now().strftime('%m/%d/%Y'), pod_name, gpu_name, gpu_count, max_utilization, max_temperature, max_power_usage, max_vram_usage])

def main():
    while True:
        pod_name = get_pod_info()
        gpu_name, gpu_count, max_utilization, max_temperature, max_power_usage, max_vram_usage = get_gpu_info()
        write_to_csv(pod_name, gpu_name, gpu_count, max_utilization, max_temperature, max_power_usage, max_vram_usage)
        time.sleep(10)  # Adjust the interval as needed

if __name__ == '__main__':
    main()
