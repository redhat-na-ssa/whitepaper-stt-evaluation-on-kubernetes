# Summary of Script Steps

## Performance Metrics Evaluated:

**Infrastructure**: What types of hardware were tested?

1. RHEL EC2 Instance `g6.xlarge 1 x NVIDIA L4` OR `g6.12xlarge 4 x NVIDIA L4`
1. OpenShift Instance ``

**Scale**:

1. Max concurrent inference endpoints
1. Queries per second

**Cost:** How much does it cost to infer?

**Resources:** How many resources does it consume to infer?

1. Container size
1. GPU
1. CPU
1. VRAM

**Speed:** How fast is the model at transcribing using the `time` command which prints

1. `real` - wall-clock time (actual elapsed time) from when the command started to when it finished.
1. `user` - total amount of CPU time spent in user mode, meaning the time the CPU spent executing the process's code (excluding kernel operations).
1. `sys` - total amount of CPU time spent in kernel mode, meaning time spent executing system calls on behalf of the process (e.g., file I/O, memory allocation). If you are using a GPU, it's likely that much of the work gets offloaded resulting in a lower number.
1. responseLatency - i

**Precision:** Floating-Point Precision Comparison for Transcription:

|Precision|Accuracy|Speed|Memory Usage|Hardware Support|ASR Models Using It|
|---|---|---|---|---|---|
|FP8 (8-bit Floating Point)|Lowest (accuracy degradation)|Fastest|Lowest|NVIDIA H100, A100 (TensorRT, CUDA 12)|Not widely used yet; experimental for some ASR models|
|FP16 (Half-Precision, 16-bit Floating Point)|Slightly reduced vs. FP32|Fast (GPU-optimized)|Lower than FP32|Most modern GPUs (NVIDIA Tensor Cores, AMD ROCm)|Faster-Whisper, NeMo ASR, Canary, Wav2Vec|
|FP32 (Full Precision, 32-bit Floating Point)|Highest (best transcription accuracy)|Slowest|Highest|Universal (CPU & GPU)|Whisper, NeMo ASR, Canary, Wav2Vec|

**Accuracy:** How accurate is the model? JiWER is a simple and fast python package to evaluate an automatic speech recognition system. It supports the following measures:

1. `Word Error Rate (WER)` – Measures the percentage of words that were incorrectly predicted compared to the reference text.

    - S = Substitutions
    - D = Deletions
    - I = Insertions
    - N = Number of words in the reference transcript
    - Lower is better.

    WER = (S + D + I) / N

1. `Match Error Rate (MER)` – Represents the fraction of words that need to be transformed (inserted, deleted, or substituted) to match the reference text. Unlike WER, it considers the total number of words in both the reference and hypothesis.

    - S = Substitutions
    - D = Deletions
    - I = Insertions
    - C = Correctly recognized words
    - Unlike WER, MER includes the total correct words in the denominator.
    - Lower is better.

    WER = (S + D + I) / (S + D + C)

1. `Word Information Lost (WIL)` – Estimates how much word-level information is lost due to errors. It penalizes deletions and substitutions while being less sensitive to insertions.

    - Related to WER but normalizes by WIP.

    WIL = WER / (1 - WIP)

1. `Word Information Preserved (WIP)` – The inverse of WIL, this measures how much word-level information is correctly preserved in the hypothesis relative to the reference.

    - Measures how much information was retained in the STT output.

    WIP = C / (C + S + D)

1. `Character Error Rate (CER)` – Similar to WER but at the character level, CER measures the percentage of incorrectly predicted characters compared to the reference text, making it useful for evaluating text with short words or heavy misspellings.

    - Similar to WER but at the character level rather than words.
    - Useful for languages with compound words or agglutinative structures.

    CER = (S + D + I) / N

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