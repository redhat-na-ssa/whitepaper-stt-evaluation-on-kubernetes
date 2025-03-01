# Summary of Script Steps

## evaluation.py

This script automates the process of running Whisper for speech-to-text transcription, evaluating its accuracy, and logging relevant metadata in a CSV file.

Key Functions:
1. Runs Whisper for Transcription
    - Executes the Whisper command with configurable model and file paths.
    - Saves the transcription output in the specified directory.
1. Captures System & Execution Details
    - Records OS version and floating point precision used.
    - Logs start time, end time, and duration of the transcription.
    - Stores the current date in MM-DD-YYYY format.
    - Evaluates Transcription Accuracy
1. Compares the Whisper output file (hypothesis.txt) with a ground truth reference file (if available).
    - Calculates WER, MER, WIL, WIP, and CER using jiwer.
1. Logs Data to CSV (evaluations.csv)
    - Appends results to a CSV file in the output_dir.
    - Ensures each run is uniquely logged with relevant details.
1. The output .csv file should look like the following:

```
model,input_file,model_name,model_dir,output_dir,start_time,end_time,duration,os_version,float_precision,date,hypothesis_file,reference_file,wer,mer,wil,wip,cer
whisper,audio-samples/jfk-audio-inaugural-address-20-january-1961.mp3,tiny.en,/tmp,/tmp,1740763629.0996196,1740763658.9717746,29.87215495109558,Red Hat Enterprise Linux release 8.10 (Ootpa),15,02-28-2025,jfk-audio-inaugural-address-20-january-1961.txt,ground-truth/jfk-audio-inaugural-address-20-january-1961.txt,0.31543624161073824,0.2923289564616448,0.4203588815754925,0.5796411184245075,0.15316832966178567
whisper,audio-samples/jfk-audio-inaugural-address-20-january-1961.mp3,small.en,/tmp,/tmp,1740763843.9718964,1740763899.5945983,55.62270188331604,Red Hat Enterprise Linux release 8.10 (Ootpa),15,02-28-2025,jfk-audio-inaugural-address-20-january-1961.txt,ground-truth/jfk-audio-inaugural-address-20-january-1961.txt,0.2692020879940343,0.2556657223796034,0.37264707369033234,0.6273529263096677,0.09459634573020603
```

1. Hypothesis File
    - the transcription file the model outputs
1. MODEL
    - whisper
    - faster-whisper
    - canary
    - nemo
    - wav2vec2
1. MODEL_SIZE
    - if whisper
        - tiny.en
        - small.en
        - medium.en
        - large
        - turbo
1. base_image
    - ubuntu 
    - ubi 
1. processor
    - cpu 
    - gpu 
1. cuda_ver
1. response_latency
1. qps
1. max_concur_endpoints
1. float_point
1. wer
1. mer
1. wil
1. wip
1. cer

## gpu-logger

The script writes to data/output/pod_gpu_usage.csv, containing:
```sh
Date, Pod Name, GPU Name, GPU Count, Max GPU Usage (%)
02/29/2025, whisper-ubuntu-gpu-harvard, NVIDIA RTX A6000, 2, 85
```

This will execute the script in the background, logging data every 10 seconds.
```sh
# start
nohup python3 data/evaluations/gpu_logger.py &
```

Find the process ID (PID) and kill it:
```sh
# stop
ps aux | grep data/evaluations/gpu_logger.py
kill <PID>
```


interesting values
1. image size
1. performance on rhel vs ocp
1. how much gpu this uses from nvidia-smi
    - Persistence-M Pwr:Usage/Cap
    - Volatile GPU-Util
    - Temp
1. vram
    - gpu = `nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits | paste -sd "," -`