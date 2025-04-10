# Manual Procedure

```sh
images=(
    "quay.io/redhat_na_ssa/speech-to-text/whisper:tiny.en-ubuntu"
)

input_files=(
    "harvard.wav"
    #"jfk-audio-inaugural-address-20-january-1961.mp3"
    #"jfk-audio-rice-university-12-september-1962.mp3"
)

reference_files=(
    "harvard.txt"
    #"ground-truth/jfk-audio-inaugural-address-20-january-1961.txt"
    #"ground-truth/jfk-audio-rice-university-12-september-1962.txt"
)

for image in "${images[@]}"; do
    model_name=$(echo "$image" | sed -E 's/.*whisper:([a-zA-Z0-9.-]+)-[a-zA-Z0-9.-]+/\1/')
    safe_model_name=$(echo "$model_name" | tr '.' '-')
    suffix=$(echo "$image" | sed -E 's/.*whisper:[a-zA-Z0-9.-]+-(.*)/\1/')
    base_container_name="whisper-${safe_model_name}-${suffix//[:]/-}"

    for i in "${!input_files[@]}"; do
        input_file="${input_files[$i]}"
        reference_file="${reference_files[$i]}"

        for mode in "cpu" "gpu"; do
            if [[ "$mode" == "gpu" ]]; then
                podman_args="--security-opt=label=disable --device nvidia.com/gpu=all"
                container_name="${base_container_name}-gpu"
            else
                podman_args=""
                container_name="$base_container_name"
            fi

            full_cmd="podman run --rm -it \
                --name \"$container_name\" \
                $podman_args \
                -v \"$(pwd)/data:/data:z\" \
                \"$image\" \
                python3 evaluation-scripts/evaluation.py \
                --model_name \"$model_name\" \
                --input \"input-samples/$input_file\" \
                --reference_file \"ground-truth/$reference_file\""

            echo
            echo "🔧 Running command for $container_name on $input_file ($mode):"
            echo "$full_cmd"
            echo

            # Actually run the command
            eval $full_cmd
        done
    done
done
```

### Evaluating Whisper on UBI9

1. pull all the UBI9 images

    ```sh
    for tag in ubi9 tiny.en-ubi9 base.en-ubi9 small.en-ubi9 medium.en-ubi9 large-ubi9 turbo-ubi9; do podman pull quay.io/redhat_na_ssa/speech-to-text/whisper:$tag; done
    ```

1. cleanup disk space

    ```sh
    podman rmi -fa
    ```

### Evaluating Whisper on UBI9-minimal

1. pull all the Ubuntu images

    ```sh
    for tag in ubi9-minimal tiny.en-ubi9-minimal base.en-ubi9-minimal small.en-ubi9-minimal medium.en-ubi9-minimal large-ubi9-minimal turbo-ubi9-minimal; do podman pull quay.io/redhat_na_ssa/speech-to-text/whisper:$tag; done
    ```

1. cleanup disk space

    ```sh
    podman rmi -fa
    ```

1. (optional) build images

    ```sh
    # Minimal builds with runtime model download
    podman build -t whisper:ubuntu crawl/openai-whisper/ubuntu/.
    podman build -t whisper:ubi9 crawl/openai-whisper/ubi/platform/.
    podman build -t whisper:ubi9-minimal crawl/openai-whisper/ubi/minimal/.

    # list images
    podman images
    ```

1. (optional) Preloaded models for faster startup or air-gapped environments

    IMPORTANT: you may run out of disk space if you attempt to run all of the builds.

    ```sh
    # ubuntu whisper models
    for model in tiny.en base.en small.en medium.en large turbo; do
    tag="whisper-${model}:ubuntu"
    echo "🔧 Building image: $tag"
    podman build --build-arg MODEL_SIZE=$model -t $tag crawl/openai-whisper/ubuntu/.
    done
    ```

    ```sh
    # ubi9-platform whisper
    for model in tiny.en base.en small.en medium.en large turbo; do
    tag="whisper-${model}:ubi9"
    echo "🔧 Building image: $tag"
    podman build --build-arg MODEL_SIZE=$model -t $tag crawl/openai-whisper/ubi/platform/.
    done
    ```

    ```sh
    # ubi9-minimal whisper
    for model in tiny.en base.en small.en medium.en large turbo; do
    tag="whisper-${model}:ubi9-minimal"
    echo "🔧 Building image: $tag"
    podman build --build-arg MODEL_SIZE=$model -t $tag crawl/openai-whisper/ubi/minimal/.
    done
    ```

1. launch host metrics
1. execute base test