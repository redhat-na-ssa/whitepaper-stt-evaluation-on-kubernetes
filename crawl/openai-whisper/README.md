# OpenAI Whisper

This README covers the steps to the container combinations for whisper model. Individual and manual steps can be found under the respective sub-dir, for example ubuntu/README.md.

|cmd|model|size|image|processor|input|deployment|platform|
|-|-|-|-|-|-|-|-|
|default|whisper|base|ubuntu|T4|Harvard|Embedded inference microservices|Linux|
|optimized| |tiny.en|ubi9|L4|JFK Inaugural Address|Decoupled model servers|Kubernetes|
| | |base.en|ubi9-minimal|A10G|JFK Rice University| | |
| | |small.en| |H100| | | |
| | |medium.en| |Intel Cascade Lake| | | |
| | |large| |AWS Graviton3| | | |
| | |turbo| |AMD EPYC 7003 (Milan)| | | |
| | | | |Intel Sapphire Rapids| | | |

## Benchmarking

TODO build UI scraper of the .csv to visualize the data

### Evaluating Whisper on Ubuntu

1. pull all the Ubuntu images from quay.io

    ```sh
    # login to quay.io
    podman login quay.io

    # pull all the ubuntu images
    for tag in ubuntu tiny.en-ubuntu base.en-ubuntu small.en-ubuntu medium.en-ubuntu large-ubuntu turbo-ubuntu; do podman pull quay.io/redhat_na_ssa/speech-to-text/whisper:$tag; done
    ```

1. from terminal 1 of 2, run the host metrics

    ```sh
    # terminal 1 of 2
    # run the podman_container_monitor script in the background
    nohup python3 data/evaluation-scripts/podman_container_monitor.py &
    ```

1. from terminal 2 of 2, loop through benchmarking the different images with the embedded models
  
  The script loops over each image (to cover different Whisper model variants), each pair of input/ground-truth files, and each hardware type (CPU and GPU).

    ```sh
    # Define the list of Whisper container images to evaluate
    images=(
        "quay.io/redhat_na_ssa/speech-to-text/whisper:tiny.en-ubuntu"
        #"quay.io/redhat_na_ssa/speech-to-text/whisper:base.en-ubuntu"
        #"quay.io/redhat_na_ssa/speech-to-text/whisper:small.en-ubuntu"
        #"quay.io/redhat_na_ssa/speech-to-text/whisper:medium.en-ubuntu"
        #"quay.io/redhat_na_ssa/speech-to-text/whisper:large-ubuntu"
        #"quay.io/redhat_na_ssa/speech-to-text/whisper:turbo-ubuntu"
    )

    # List of input audio files to transcribe
    input_files=(
        "harvard.wav"
        #"jfk-audio-inaugural-address-20-january-1961.mp3"
        #"jfk-audio-rice-university-12-september-1962.mp3"
    )

    # Corresponding ground truth transcripts for evaluation
    reference_files=(
        "harvard.txt"
        #"ground-truth/jfk-audio-inaugural-address-20-january-1961.txt"
        #"ground-truth/jfk-audio-rice-university-12-september-1962.txt"
    )

    # Loop through each Whisper container image
    for image in "${images[@]}"; do
        # Extract the model name (e.g., tiny.en) from the image tag
        model_name=$(echo "$image" | sed -E 's/.*whisper:([a-zA-Z0-9.-]+)-[a-zA-Z0-9.-]+/\1/')
        
        # Convert dots to hyphens for safe container naming (e.g., tiny-en)
        safe_model_name=$(echo "$model_name" | tr '.' '-')
        
        # Extract the image suffix (e.g., ubuntu)
        suffix=$(echo "$image" | sed -E 's/.*whisper:[a-zA-Z0-9.-]+-(.*)/\1/')
        
        # Create a base container name like whisper-tiny-en-ubuntu
        base_container_name="whisper-${safe_model_name}-${suffix//[:]/-}"

        # Loop through each input/reference file pair
        for i in "${!input_files[@]}"; do
            input_file="${input_files[$i]}"
            reference_file="${reference_files[$i]}"

            # Run the model on both CPU and GPU
            for mode in "cpu" "gpu"; do
                if [[ "$mode" == "gpu" ]]; then
                    # Enable GPU access in the container
                    podman_args="--security-opt=label=disable --device nvidia.com/gpu=all"
                    container_name="${base_container_name}-gpu"
                else
                    # Default to CPU, no special runtime args
                    podman_args=""
                    container_name="$base_container_name"
                fi

                # Construct the full podman command to execute
                full_cmd="podman run --rm -it \
                    --name \"$container_name\" \
                    $podman_args \
                    -v \"$(pwd)/data:/data:z\" \
                    \"$image\" \
                    python3 evaluation-scripts/evaluation.py \
                    --model_name \"$model_name\" \
                    --input \"input-samples/$input_file\" \
                    --reference_file \"ground-truth/$reference_file\""

                # Print and run the command
                echo
                echo "🔧 Running command for $container_name on $input_file ($mode):"
                echo "$full_cmd"
                echo

                # Run the constructed command
                eval $full_cmd
            done
        done
    done

    ```
1. collapse the csv files

    ```sh
    sort -u data/metrics/*.csv >> "data/metrics/evaluation-$(date +"%Y-%m-%d_%H%M%S").csv"
    ```

1. from terminal 1 of 2, stop the host metrics

    ```sh
    # terminal 1 of 2
    Ctrl+C

    # find the process
    ps aux | grep podman_container_monitor.py

    # stop the process via id (i.e. pid 12345)
    kill 12345
    ```

1. cleanup disk space

    ```sh
    podman rmi -fa
    ```

### Evaluating Whisper on UBI9 Platform

1. pull all the UBI9 images from quay.io

    ```sh
    # login to quay.io
    podman login quay.io

    # pull all the ubuntu images
    for tag in ubi9 tiny.en-ubi9 base.en-ubi9 small.en-ubi9 medium.en-ubi9 large-ubi9 turbo-ubi9; do podman pull quay.io/redhat_na_ssa/speech-to-text/whisper:$tag; done
    ```

1. from terminal 1 of 2, run the host metrics

    ```sh
    # terminal 1 of 2
    # run the podman_container_monitor script in the background
    nohup python3 data/evaluation-scripts/podman_container_monitor.py &
    ```

1. from terminal 2 of 2, loop through benchmarking the different images with the embedded models
  
  The script loops over each image (to cover different Whisper model variants), each pair of input/ground-truth files, and each hardware type (CPU and GPU).

    ```sh
    # Define the list of Whisper container images to evaluate
    images=(
        "quay.io/redhat_na_ssa/speech-to-text/whisper:tiny.en-ubi9"
        #"quay.io/redhat_na_ssa/speech-to-text/whisper:base.en-ubi9"
        #"quay.io/redhat_na_ssa/speech-to-text/whisper:small.en-ubi9"
        #"quay.io/redhat_na_ssa/speech-to-text/whisper:medium.en-ubi9"
        #"quay.io/redhat_na_ssa/speech-to-text/whisper:large-ubi9"
        #"quay.io/redhat_na_ssa/speech-to-text/whisper:turbo-ubi9"
    )

    # List of input audio files to transcribe
    input_files=(
        "harvard.wav"
        #"jfk-audio-inaugural-address-20-january-1961.mp3"
        #"jfk-audio-rice-university-12-september-1962.mp3"
    )

    # Corresponding ground truth transcripts for evaluation
    reference_files=(
        "harvard.txt"
        #"ground-truth/jfk-audio-inaugural-address-20-january-1961.txt"
        #"ground-truth/jfk-audio-rice-university-12-september-1962.txt"
    )

    # Loop through each Whisper container image
    for image in "${images[@]}"; do
        # Extract the model name (e.g., tiny.en) from the image tag
        model_name=$(echo "$image" | sed -E 's/.*whisper:([a-zA-Z0-9.-]+)-[a-zA-Z0-9.-]+/\1/')
        
        # Convert dots to hyphens for safe container naming (e.g., tiny-en)
        safe_model_name=$(echo "$model_name" | tr '.' '-')
        
        # Extract the image suffix (e.g., ubuntu)
        suffix=$(echo "$image" | sed -E 's/.*whisper:[a-zA-Z0-9.-]+-(.*)/\1/')
        
        # Create a base container name like whisper-tiny-en-ubuntu
        base_container_name="whisper-${safe_model_name}-${suffix//[:]/-}"

        # Loop through each input/reference file pair
        for i in "${!input_files[@]}"; do
            input_file="${input_files[$i]}"
            reference_file="${reference_files[$i]}"

            # Run the model on both CPU and GPU
            for mode in "cpu" "gpu"; do
                if [[ "$mode" == "gpu" ]]; then
                    # Enable GPU access in the container
                    podman_args="--security-opt=label=disable --device nvidia.com/gpu=all"
                    container_name="${base_container_name}-gpu"
                else
                    # Default to CPU, no special runtime args
                    podman_args=""
                    container_name="$base_container_name"
                fi

                # Construct the full podman command to execute
                full_cmd="podman run --rm -it \
                    --name \"$container_name\" \
                    $podman_args \
                    -v \"$(pwd)/data:/data:z\" \
                    \"$image\" \
                    python3 evaluation-scripts/evaluation.py \
                    --model_name \"$model_name\" \
                    --input \"input-samples/$input_file\" \
                    --reference_file \"ground-truth/$reference_file\""

                # Print and run the command
                echo
                echo "🔧 Running command for $container_name on $input_file ($mode):"
                echo "$full_cmd"
                echo

                # Run the constructed command
                eval $full_cmd
            done
        done
    done

    ```

1. collapse the csv files

    ```sh
    sort -u data/metrics/*.csv >> "data/metrics/evaluation-$(date +"%Y-%m-%d_%H%M%S").csv"
    ```

1. from terminal 1 of 2, stop the host metrics

    ```sh
    # terminal 1 of 2
    Ctrl+C

    # find the process
    ps aux | grep podman_container_monitor.py

    # stop the process via id (i.e. pid 12345)
    kill 12345
    ```

1. cleanup disk space

    ```sh
    podman rmi -fa
    ```

### Evaluating Whisper on UBI9-minimal Platform

1. pull all the UBI9-minimal images from quay.io

    ```sh
    # login to quay.io
    podman login quay.io

    # pull all the UBI9-minimal images
    for tag in ubi9-minimal tiny.en-ubi9-minimal base.en-ubi9-minimal small.en-ubi9-minimal medium.en-ubi9-minimal large-ubi9-minimal turbo-ubi9-minimal; do podman pull quay.io/redhat_na_ssa/speech-to-text/whisper:$tag; done
    ```

1. from terminal 1 of 2, run the host metrics

    ```sh
    # terminal 1 of 2
    # run the podman_container_monitor script in the background
    nohup python3 data/evaluation-scripts/podman_container_monitor.py &
    ```

1. from terminal 2 of 2, loop through benchmarking the different images with the embedded models
  
  The script loops over each image (to cover different Whisper model variants), each pair of input/ground-truth files, and each hardware type (CPU and GPU).

    ```sh
    # Define the list of Whisper container images to evaluate
    images=(
        "quay.io/redhat_na_ssa/speech-to-text/whisper:tiny.en-ubi9-minimal"
        #"quay.io/redhat_na_ssa/speech-to-text/whisper:base.en-ubi9-minimal"
        #"quay.io/redhat_na_ssa/speech-to-text/whisper:small.en-ubi9-minimal"
        #"quay.io/redhat_na_ssa/speech-to-text/whisper:medium.en-ubi9-minimal"
        #"quay.io/redhat_na_ssa/speech-to-text/whisper:large-ubi9-minimal"
        #"quay.io/redhat_na_ssa/speech-to-text/whisper:turbo-ubi9-minimal"
    )

    # List of input audio files to transcribe
    input_files=(
        "harvard.wav"
        #"jfk-audio-inaugural-address-20-january-1961.mp3"
        #"jfk-audio-rice-university-12-september-1962.mp3"
    )

    # Corresponding ground truth transcripts for evaluation
    reference_files=(
        "harvard.txt"
        #"ground-truth/jfk-audio-inaugural-address-20-january-1961.txt"
        #"ground-truth/jfk-audio-rice-university-12-september-1962.txt"
    )

    # Loop through each Whisper container image
    for image in "${images[@]}"; do
        # Extract the model name (e.g., tiny.en) from the image tag
        model_name=$(echo "$image" | sed -E 's/.*whisper:([a-zA-Z0-9.-]+)-[a-zA-Z0-9.-]+/\1/')
        
        # Convert dots to hyphens for safe container naming (e.g., tiny-en)
        safe_model_name=$(echo "$model_name" | tr '.' '-')
        
        # Extract the image suffix (e.g., ubuntu)
        suffix=$(echo "$image" | sed -E 's/.*whisper:[a-zA-Z0-9.-]+-(.*)/\1/')
        
        # Create a base container name like whisper-tiny-en-ubuntu
        base_container_name="whisper-${safe_model_name}-${suffix//[:]/-}"

        # Loop through each input/reference file pair
        for i in "${!input_files[@]}"; do
            input_file="${input_files[$i]}"
            reference_file="${reference_files[$i]}"

            # Run the model on both CPU and GPU
            for mode in "cpu" "gpu"; do
                if [[ "$mode" == "gpu" ]]; then
                    # Enable GPU access in the container
                    podman_args="--security-opt=label=disable --device nvidia.com/gpu=all"
                    container_name="${base_container_name}-gpu"
                else
                    # Default to CPU, no special runtime args
                    podman_args=""
                    container_name="$base_container_name"
                fi

                # Construct the full podman command to execute
                full_cmd="podman run --rm -it \
                    --name \"$container_name\" \
                    $podman_args \
                    -v \"$(pwd)/data:/data:z\" \
                    \"$image\" \
                    python3 evaluation-scripts/evaluation.py \
                    --model_name \"$model_name\" \
                    --input \"input-samples/$input_file\" \
                    --reference_file \"ground-truth/$reference_file\""

                # Print and run the command
                echo
                echo "🔧 Running command for $container_name on $input_file ($mode):"
                echo "$full_cmd"
                echo

                # Run the constructed command
                eval $full_cmd
            done
        done
    done

    ```

*************

#### Run Host Metrics script

From your VM with GPUs

```sh
# Terminal 1 of 2
# Run the podman_container_monitor script in the background
nohup python3 data/evaluation-scripts/podman_container_monitor.py &
```

#### Whisper Ubuntu Test on CPU

```sh
# Terminal 2 of 2
## 1 - Whisper Ubuntu CPU
podman run --rm -it --name whisper-ubuntu-cpu -v $(pwd)/data:/data:z localhost/whisper:ubuntu /bin/bash

## For loop through each model twice to capture pre-downloaded performance
for model in tiny.en base.en small.en medium.en large turbo; do
  # First run
  python3 evaluation-scripts/evaluation.py --model_name $model
  # Second run with models cached
  python3 evaluation-scripts/evaluation.py --model_name $model
done

## Review the data captured run `sort -u /tmp/*.csv`

## Copy the .csv data from /tmp to a local output dir for downstream visualization
sort -u /tmp/*.csv >> "metrics/$(date +"%Y-%m-%d_%H%M%S").csv"
sh /data/evaluation-scripts/collapse-csvs.sh

## exit pod
exit
```

#### Whisper Ubuntu Test on GPU

```sh
## 2 - Whisper Ubuntu GPU
podman run --rm -it --name whisper-ubuntu-gpu --security-opt=label=disable --device nvidia.com/gpu=all -v $(pwd)/data:/data:z localhost/whisper:ubuntu /bin/bash

## For loop through each model twice to capture pre-downloaded performance
for model in tiny.en base.en small.en medium.en large turbo; do
  # First run
  python3 evaluation-scripts/evaluation.py --model_name $model
  # Second run with models cached
  python3 evaluation-scripts/evaluation.py --model_name $model
done

## Copy the .csv data to local output dir
sort -u /tmp/*.csv >> metrics/whisper_harvard_metrics.csv

## exit pod
exit
```

#### Whisper UBI9 Platform Test on CPU

```sh
## 3 - Whisper UBI CPU
podman run --rm -it --name whisper-ubi-cpu -v $(pwd)/data:/data:z localhost/whisper:ubi9 /bin/bash

## For loop through each model twice to capture pre-downloaded performance
for model in tiny.en base.en small.en medium.en large turbo; do
  # First run
  python3 evaluation-scripts/evaluation.py --model_name $model
  # Second run with models cached
  python3 evaluation-scripts/evaluation.py --model_name $model
done

## Copy the .csv data to local output dir
## You may have to chmod 755 data/metrics/metrics/whisper_harvard_metrics.csv
sort -u /tmp/*.csv >> metrics/whisper_harvard_metrics.csv

## exit pod
exit
```

#### Whisper UBI9 Platform Test on GPU

```sh
## 4 - Whisper UBI GPU
podman run --rm -it --name whisper-ubi-gpu --security-opt=label=disable --device nvidia.com/gpu=all -v $(pwd)/data:/data:z localhost/whisper:ubi9 /bin/bash

## For loop through each model twice to capture pre-downloaded performance
for model in tiny.en base.en small.en medium.en large turbo; do
  # First run
  python3 evaluation-scripts/evaluation.py --model_name $model
  # Second run with models cached
  python3 evaluation-scripts/evaluation.py --model_name $model
done

## Copy the .csv data to local output dir
## You may have to chmod 777 data/output
sort -u /tmp/*.csv >> metrics/whisper_harvard_metrics.csv

## exit pod
exit
```

#### Copy over metrics to host

```sh
# Terminal 1 of 2
# Copy output to host from pod
cp metrics/pod_gpu_usage.csv .

# Stop the podman_container_monitor.py script
ps aux | grep podman_container_monitor
```

### Addtional examples
#### JFK speeches
```bash
python3 evaluation-scripts/evaluation.py --model_name $model --input input-samples/jfk-audio-inaugural-address-20-january-1961.mp3  --reference_file ground-truth/jfk-audio-inaugural-address-20-january-1961.txt --hypothesis_file /tmp/jfk-audio-inaugural-address-20-january-1961.txt --log_level DEBUG
```
## Whisper Optimizations

### Best Initial Test Command

```sh
whisper input-samples/harvard.wav \
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