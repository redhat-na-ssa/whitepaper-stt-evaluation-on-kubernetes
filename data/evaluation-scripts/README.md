# Summary of Script Steps

## gpu_logger script

This script collects system information, specifically about pods (likely using Podman), CPU, and GPU, then logs this data to a CSV file every 10 seconds. It runs in the background and writes to a CSV file (pod_host_usage.csv), which stores the following columns:

- date: The current date in YYYY-MM-DD format.
- timestamp: A timestamp in HHMMSS format.
- pod name: The name of the Pod (or 'No Pod' if no pod is running).
- processor/gpu name: The GPU name, or CPU model if GPU information is unavailable.
- core/gpu count: The number of CPU cores or GPUs.
- max usage (%): The maximum GPU utilization in percentage.
- max gpu temperature (C): The maximum GPU temperature in Celsius.
- max pwr:usage/cap (%): The power usage as a percentage of the maximum power limit.
- max vram usage (%): The percentage of VRAM used.

## evaluation script

This script is designed to run a transcription process using a Whisper model, evaluate its accuracy against a reference text, and log the results to a CSV file. The script generates a CSV file that contains the following columns:

- date: The current date in YYYY-MM-DD format.
- timestamp: A timestamp in HHMMSS format.
- model: The name or path of the model (Whisper in this case).
- model_name: The name of the Whisper model used (e.g., tiny.en).
- model_dir: The directory where the model is stored.
- input_file: The path to the input audio file.
- output_dir: The directory where the output is stored.
- start_time: The start time of the transcription process.
- end_time: The end time of the transcription process.
- duration: The time taken for the transcription process (end time - start time).
- wer: The Word Error Rate between the hypothesis and reference texts.
- mer: The Match Error Rate between the hypothesis and reference texts.
- wil: The Word Information Lost metric.
- wip: The Word Information Preserved metric.
- cer: The Character Error Rate.
- floating_point_format: Use PyTorch or TensorFlow to detect FP16/FP32.
- executed_command: The command that was executed (for logging purposes).


## JiWER

How accurate is the model? JiWER is a simple and fast python package to evaluate an automatic speech recognition system. It supports the following measures:

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