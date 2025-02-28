# Crawl

OpenAI Whisper interactive session with local audio files on a laptop/server:

- [x] Ubuntu
  - [x] CPU ~6G
  - [x] GPU ~22G
- [x] UBI
  - [ ] CPU
  - [ ] GPU

## Ubuntu

### Build CPU image

`podman build -t whisper-cpu:ubuntu crawl/openai-whisper/ubuntu/.`

### Build GPU image

`podman build -t whisper-gpu:ubuntu crawl/openai-whisper/ubuntu/gpu/.`

### Run container on CPU

```sh
podman run --rm -it \
    -v $(pwd)/data:/data:z \
    localhost/whisper-cpu:ubuntu
```

### Run container on GPU

```sh
podman run --rm -it \
    -v $(pwd)/data:/data:z \
    --security-opt=label=disable \
    --device nvidia.com/gpu=all \
    localhost/whisper-gpu:ubuntu
```

### Execute transcriptions

Whisper MODEL options:
- tiny.en, tiny, base.en, base, small.en, small, medium.en, medium, large, turbo

AUDIO options:

1. jfk-audio-inaugural-address-20-january-1961
1. jfk-audio-rice-university-12-september-1962

```sh
# different model sizes transcribing jfk-audio-inaugural-address-20-january-1961
python3 evaluations/script.py \
        --model whisper \
        --model_size tiny.en \
        --base_image ubuntu \
        --platform ubuntu \
        --processor gpu \
        --input_file audio-samples/jfk-audio-inaugural-address-20-january-1961.mp3 \
        ground-truth/jfk-audio-inaugural-address-20-january-1961.txt \
        output
```

## UBI

### Build UBI CPU image

`podman build -t whisper:ubi crawl/openai-whisper/ubi/.`

### Run UBI container on CPU

```sh
podman run --rm -it \
    -v $(pwd)/data:/data:z \
    localhost/whisper:ubi
```

### Run UBI container on GPU

```sh
podman run --rm -it \
    --security-opt=label=disable \
    --device nvidia.com/gpu=all \
    -v $(pwd)/data:/data:z \
    localhost/whisper:ubi
```

### Execute transcriptions

```sh
# different model sizes transcribing jfk-audio-inaugural-address-20-january-1961
python3 evaluations/script.py \
        --model whisper \
        --model_size tiny.en \
        --base_image ubi \
        --platform rhel \
        --processor gpu \
        --input_file audio-samples/jfk-audio-inaugural-address-20-january-1961.mp3 \
        ground-truth/jfk-audio-inaugural-address-20-january-1961.txt \
        output
```

## Whisper Optimizations

### Best Initial Test Command

```sh
whisper ground-truth/jfk-audio-inaugural-address-20-january-1961.txt \
    --model large \
    --language en \
    --beam_size 10 \
    --temperature 0 \
    --patience 2 \
    --suppress_tokens -1 \
    --compression_ratio_threshold 2.0 \
    --logprob_threshold -0.5 \
    --no_speech_threshold 0.4
```

Initial experimentation parameters:

- Try a larger model (medium or large) if you are using tiny, base, or small.
- If you know the language, set it explicitly to avoid misdetections.
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