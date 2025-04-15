# OpenAI Whisper

This README covers the steps to the container combinations for whisper model. Individual and manual steps can be found under the respective sub-dir:

1. [Ubuntu w/Whisper](ubuntu/README.md)
1. [UBI9 w/Whisper](ubi/platform/README.md)
1. [UBI9-minimal w/Whisper](ubi/minimal/README.md)

The following steps cover what AI teams might be experimenting with to make decisions about security, storage, resources, accuracy and optimization.

## Whisper Transcription Experiment Workflow

1. Provision one of four RHEL VMs with a GPU.
1. Pull six Ubuntu Whisper images from Quay.io.
1. Start container monitoring in the background.
1. For each of the six container images:
    - For each of the three audio samples:
        - Launch a new container using the image and transcribe the sample on the host CPU with:
            1. A fast command, saving the output with a unique filename.
            1. A complex command, saving the output with a unique filename.
        - Launch a new container using the image and transcribe the sample on the host GPU with: 
            1. A fast command, saving the output with a unique filename.
            1. A complex command, saving the output with a unique filename.
1. Stop container monitoring.
1. Remove the six Ubuntu Whisper images from the host.
1. Repeat steps 2–6 for the six UBI9 then UBI9-minimal Whisper images from Quay.io.
1. Repeat the entire process for all four RHEL VMs.

TODO build UI scraper of the .csv to visualize the data

Total Transcription Files Calculation:

- 4 VMs
- 18 container images total
- 3 audio samples per container
- 2 command types (fast, complex)
- 2 modes (CPU, GPU)

```sh
4 VMs × 18 containers × 3 samples × 2 commands × 2 modes
= 864 transcription files per VM
× 4 VMs
= 3,456 transcription files total
```

## Whisper Transcription Experiment

Recommend launching 3 terminal sessions on the same VM:

1. to the monitor NVIDIA Usage `watch nvidia-smi`
1. to launch the `podman_container_monitor.py` in the background
1. to monitor the output of the `run-whisper-benchmark.sh` script

[Provision the RHEL VM w/GPUs](https://github.com/redhat-na-ssa/whitepaper-stt-evaluation-on-kubernetes/blob/main/crawl/RHEL_GPU.md)

Pull six Ubuntu Whisper images from Quay.io.
- p5.48xlarge

```sh
# login to quay.io
podman login quay.io

# pull all the ubuntu images
for tag in ubuntu tiny.en-ubuntu base.en-ubuntu small.en-ubuntu medium.en-ubuntu large-ubuntu turbo-ubuntu; do podman pull quay.io/redhat_na_ssa/speech-to-text/whisper:$tag; done
```

Clone the repo

```sh
# clone
git clone https://github.com/redhat-na-ssa/whitepaper-stt-evaluation-on-kubernetes.git
```

Start monitoring GPU and CPU Usage

```sh
# watch -n 1 — Runs the full block every second
# -t — Removes the header timestamp from watch to make output cleaner
# nvidia-smi — Displays GPU utilization
# mpstat -P ALL 1 1 — Samples CPU core usage over 1 second

You can change the 1 1 to 0.5 1 for faster snapshots
watch -n 1 -t '
  echo "== NVIDIA GPU Usage ==";
  nvidia-smi;
  echo "";
  echo "== CPU Core Usage ==";
  mpstat -P ALL 1 1 | tail -n +4
'

```

Start container monitoring in the background

```sh
# terminal 2 of 3
# run the podman_container_monitor script in the background
nohup python3 data/evaluation-scripts/podman_container_monitor.py &
```

Loop through all of the experiments for Ubuntu: model size, audio file, cpu, gpu, fast and complex command

```sh
# terminal 3 of 3
# run the run-whisper-benchmark in parallel
./data/evaluation-scripts/run-whisper-benchmark.sh --flavor=ubuntu --instance=g5.12xlarge

# just in case to stop this job if it freezes
podman ps -a -q | xargs podman rm -f
```

Stop watching NVIDIA

```sh
  # terminal 1 of 3
  Ctrl+C
```

Stop the host metrics

  ```sh
  # terminal 2 of 3
  Ctrl+C

  # find the process
  ps aux | grep podman_container_monitor.py

  # stop the process via id (i.e. pid 12345)
  kill 12345
  ```

1. cleanup disk space

```sh
./data/evaluation-scripts/cleanup-benchmark-results.sh
```

## Initial experimentation arguments:

- Adjust decoding:
  - Beam Search (--beam_size): Increases accuracy by considering multiple possibilities.
  - Temperature (--temperature): Lower values (0-0.2) make outputs more deterministic.
  - Patience (--patience): Allows the model to explore better alternatives.
- Avoids unwanted symbols that could lower accuracy.
- Improve robustness against hallucinations:
  - Compression Ratio Threshold (--compression_ratio_threshold): Filters out bad transcriptions.
  - Log Probability Threshold (--logprob_threshold): Removes segments with low confidence.
  - No Speech Threshold (--no_speech_threshold): Filters out silent parts.
- Enable word timestamps:
  - Useful for reviewing accuracy at the word level.

### Here’s a breakdown of some key Whisper parameters and what they do:

```sh
# Basic Parameters
audio: The input audio file(s) to be transcribed.
--model MODEL: Specifies which Whisper model to use. Example values: tiny, base, small, medium, large, turbo (default: turbo).
--model_dir MODEL_DIR: Path where model files are stored (default is ~/.cache/whisper).
--device DEVICE: Hardware for processing. Options:
cpu (default) for CPU usage.
cuda or mps for GPU acceleration (if available).
Output Parameters
--output_dir OUTPUT_DIR: Where to save the output files.
--output_format {txt,vtt,srt,tsv,json,all}: Format of the transcription output.
txt: Plain text.
vtt: WebVTT (subtitles).
srt: SubRip (subtitles).
tsv: Tab-separated values.
json: JSON format.
all: Saves in all formats.

# Transcription & Translation
--task {transcribe,translate}:
    transcribe: Converts spoken audio to text in the same language.
    translate: Translates non-English audio to English.
--language <language>: Manually specify the spoken language (e.g., en for English). If omitted, Whisper auto-detects.

# Decoding Parameters (Affecting Accuracy & Speed)
--temperature TEMPERATURE: Controls randomness (default 0 means deterministic, higher values increase variation).
--best_of BEST_OF: Number of candidates when using sampling (temperature > 0).
--beam_size BEAM_SIZE: Number of beams for beam search (used when temperature = 0).
--patience PATIENCE: Affects beam search, allowing it to consider longer alternatives (default 1.0).
--length_penalty LENGTH_PENALTY: Adjusts preference for shorter or longer transcriptions.

# Error Handling & Robustness
--temperature_increment_on_fallback TEMPERATURE_INCREMENT_ON_FALLBACK: Increases temperature when decoding fails, making the model try different outputs.
--compression_ratio_threshold COMPRESSION_RATIO_THRESHOLD: Helps detect hallucinations (false transcriptions) by analyzing compression ratios.
--logprob_threshold LOGPROB_THRESHOLD: If average log probability of words is too low, the output is considered unreliable.
--no_speech_threshold NO_SPEECH_THRESHOLD: If the probability of silence (<|nospeech|>) is high, the segment is skipped.

# Formatting & Word Timing
--word_timestamps WORD_TIMESTAMPS: Enables word-level timestamps (default: False).
--prepend_punctuations & --append_punctuations: Defines how punctuation is attached to words when using --word_timestamps True.
--highlight_words HIGHLIGHT_WORDS: Underlines words in subtitles as they are spoken.

# Performance Tweaks
--threads THREADS: Number of CPU threads to use.
--fp16 FP16: Uses 16-bit floating-point precision for inference (default: True for GPUs, False for CPU).
--clip_timestamps CLIP_TIMESTAMPS: Allows processing only specific audio segments.
```

## Resources

- [Official NVIDIA docs](https://docs.nvidia.com/ai-enterprise/deployment/rhel-with-kvm/latest/podman.html)
- [Allow access to host GPU](https://thenets.org/how-to-use-nvidia-gpu-on-podman-rhel-fedora/)
- [Dataset](https://www.openslr.org/12)