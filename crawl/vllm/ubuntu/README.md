# vLLM on Ubuntu

## Overview

This guide crawls you through vLLM for two common model deployment scenarios:

1. Embedded inference microservices
1. Loading the models at runtime.
1. Decoupled model servers.

---

## Learning Objectives

- Continuation of the pattern moving from Dockerfiles on Linux to Kubernetes deployment patterns.
- Compare transcription performance and latency across different serving patterns.
- Build intuition for scaling with embedded inferences microservices and decoupled model serving.

---

## Questions to Explore

| **Questions**| **Answers**|
|---------------------------------------------------|-|
| How big are the container images getting? | |
| What is the security posture (CVE report) of these model images (packages vs. model)? | |
| What models can be served with vLLM? | |
| What modalities or tasks are supported with vLLM? | |
| Loading the model at runtime versus embedding the model. | |
| Performance gains from embedded versus decoupled patters.  | |
| Making data driven decisions from experiments.     | |
| Should you target CPU, GPU or Both?                | |
| Should you always have models warm?                | |
| What was the fastest transcription?                | |
| What was the slowest transcription?                | |
| When do you choose embedded versus decoupled serving? | |

---

## Procedure

Prerequisites:

Minimal Prereqs [provisioned with this procedure](https://github.com/redhat-na-ssa/whitepaper-stt-evaluation-on-kubernetes/blob/main/walk/RHEL_GPU.md):

1. SSH into your VM
1. Cloned this repo on the VM
1. Navigated to the repo root
1. Completed the [VM w/GPU provisioning](walk/RHEL_GPU.md)
1. HugginFace access token + CLI python3 -m pip install huggingface-hub

---

## Search vllm container in a public repo

```bash
# search for vllm
podman search vllm

# pull image
podman pull docker.io/vllm/vllm-openai

# check the baseos
skopeo inspect docker://docker.io/vllm/vllm-openai | jq '.Labels'

# output
# {
#   "maintainer": "NVIDIA CORPORATION <cudatools@nvidia.com>",
#   "org.opencontainers.image.ref.name": "ubuntu",
#   "org.opencontainers.image.version": "22.04"
# }
```
---

## Support vLLM Modalities

Modalities are supported **depending on the model** [source](https://docs.vllm.ai/en/latest/models/supported_models.html#list-of-multimodal-language-models):

1. [Text](https://docs.vllm.ai/en/latest/models/supported_models.html#id7) - Any text generation model can be converted into an embedding model by passing --task embed.
1. Image
1. Video
1. [Audio](https://docs.vllm.ai/en/latest/models/supported_models.html#transcription) - Speech2Text models trained specifically for Automatic Speech Recognition.

Important notes:

- with vLLM V0 - To enable multiple multi-modal items per text prompt in vLLM V0, you have to set `limit_mm_per_prompt` (offline inference) or `--limit-mm-per-prompt` (online serving).
- This is no longer required if you are using vLLM V1.

### What does "Supported" mean

[Support Policy](https://docs.vllm.ai/en/latest/models/supported_models.html#model-support-policy) - It’s best effort, not officially supported.

> ⚠️ Model integration and maintenance are best-effort and community-driven. There is no formal support guarantee, especially for less commonly used models. Contributions are welcome and appreciated, but functionality may vary.

1. Add Models: Community PRs welcome — especially from model creators.
1. Review Criteria: Focus on output quality, not exact match with other frameworks.
1. Accuracy: Some differences expected due to performance optimizations.
1. Bug Fixes: Report issues or submit fixes via PRs (notify original authors when possible).
1. Stay Updated: Watch vllm/model_executor/models for changes.
1. Priorities: Popular models get more attention; others rely on community upkeep.

## Audio

| Model Name              | Hugging Face Repo                           | Task         | Notes                                 |
|-------------------------|---------------------------------------------|--------------|---------------------------------------|
| OpenAI Whisper          | `openai/whisper-small`                      | Transcription| Supports multiple model sizes         |
| IBM Granite Speech      | `ibm-granite/granite-speech-3.3-8b`         | Transcription| Beam search recommended               |
| Qwen2 Audio             | `Qwen/Qwen2-Audio-7B-Instruct`              | Transcription| Audio input only                      |
| Qwen2.5 Omni            | `Qwen/Qwen2.5-Omni`                         | Transcription| Multi-modal (text, audio, image, etc.)|
| MiniCPM                 | `openbmb/MiniCPM`                           | Transcription| Lightweight and fast                  |
| Ultravox                | `ultravox/ultravox`                         | Transcription| Optimized for performance             |

Explanation of common Audio tasks:

1. Transcription → Convert spoken audio to text in the same language
1. Translation → Convert non-English speech to English text
1. Language Detection → Auto-detect spoken language (used implicitly)
1. Timestamps → Include word or phrase-level time codes
1. (Future) Diarization → Separate and label different speakers

## Review vLLM Requirements

See [vLLM GitHub](https://docs.vllm.ai/en/latest/getting_started/quickstart.html) for prerequisites:  
1. Python
1. model specific package requirements
1. etc.

## Review vLLM Audio Examples

[Source](https://docs.vllm.ai/en/latest/getting_started/examples/audio_language.html)

This runs your own script audio_language.py, which:

- Uses the offline vLLM Python API via LLM(...) constructor.
- Triggers a warm-up profiling pass (profile_run) to benchmark memory usage.
- If FlashAttention is enabled (even via defaults), it tries to run a forward pass before input is prepared, causing key=None → TypeError.

For the following steps, we will invoke vllm-openai’s OpenAI-compatible API server, which:

- Uses the CLI entrypoint, e.g. python3 -m vllm.entrypoints.openai.api_server.
- Loads Whisper via the --task transcription flag, which is officially supported by vLLM's OpenAIRouter.
- Internally routes to: `@router.post("/v1/audio/transcriptions") ...` which explicitly handles the Whisper audio pipeline with custom preprocessing and backend logic.

Result: Whisper is loaded and executed through a supported fast path, and it avoids the internal profiling that triggers FlashAttention crashes.

### Loading the model at runtime in a container with vLLM on GPU

```bash
# Terminal 1
# Create the directory before running the container
mkdir -p ~/.cache/huggingface

# Build the Dockerfile with the same version
podman build -t vllm-whisper-runtime -f crawl/vllm/ubuntu/Dockerfile.runtime crawl/vllm/ubuntu/

# Run it - PASS
podman run --rm -it \
  --security-opt=label=disable \
  --device nvidia.com/gpu=all \
  -p 8000:8000 \
  -v ~/.cache/huggingface:/root/.cache/huggingface:Z \
  vllm-whisper-runtime \
  --model openai/whisper-tiny.en \
  --task transcription \
  --dtype=half

# The above command works
# This invokes vllm-openai’s OpenAI-compatible API server, which:
#   1. Uses the CLI entrypoint, e.g. python3 -m vllm.entrypoints.openai.api_server.
#   2. Loads Whisper via the --task transcription flag, which is officially supported by vLLM's OpenAIRouter.
#   3. Internally routes to: @router.post("/v1/audio/transcriptions") ...
#      which explicitly handles the Whisper audio pipeline with custom preprocessing and backend logic.
#   Result: Whisper is loaded and executed through a supported fast path, and it avoids the internal profiling that triggers FlashAttention crashes.

# export HUGGING_FACE_HUB_TOKEN=your_hf_token  # replace with actual token

# The below command fails
# This runs the vLLM script audio_language.py, which:
#   1. Uses the offline vLLM Python API via LLM(...) constructor.
#   2. Triggers a warm-up profiling pass (profile_run) to benchmark memory usage.
#   3. If FlashAttention is enabled (even via defaults), it tries to run a forward pass before input is prepared, causing key=None → TypeError.
#   Result: vLLM still sometimes uses FlashAttention in profile mode due to unresolved internal logic. This is a known issue when using Whisper or any encoder-decoder mode

# Run it - FAILS
# --model-type expects: granite_speech, minicpmo, phi4_mm, qwen2_audio, qwen2_5_omni, ultravox, whisper
podman run --rm -it \
  --security-opt=label=disable \
  --device nvidia.com/gpu=all \
  -v ~/.cache/huggingface:/root/.cache/huggingface \
  -v $(pwd):/workspace \
  --env HUGGING_FACE_HUB_TOKEN=$HUGGING_FACE_HUB_TOKEN \
  --env VLLM_ATTENTION_BACKEND=torch \
  --ipc=host \
  -w /workspace \
  --entrypoint /bin/bash \
  vllm-whisper-runtime \
  -c 'echo $VLLM_ATTENTION_BACKEND; python3 data/input-samples/audio_language.py --model whisper'

# Terminal 2
# Transcribe - PASS
curl http://localhost:8000/v1/audio/transcriptions \
  -X POST \
  -H "Content-Type: multipart/form-data" \
  -F file=@data/input-samples/harvard.wav \
  -F model=openai/whisper-tiny.en

# expected output
# {"text":" The stale smell of old beer lingers. It takes heat to bring out the odor. A cold dip restores health and zest. A salt pickle tastes fine with ham. Tacos al pastor are my favorite. A zestful food is the hot cross bun."}
```

### Embed the model in a container with vLLM GPU disconnected testing

Review vLLM Audio Offline Examples - [Source](https://docs.vllm.ai/en/latest/getting_started/examples/audio_language.html)

Since we're loading a local model from /models/whisper-tiny.en, you must manually set its served name like so:

1. `--model` /models/whisper-tiny.en \
1. `--served-model-name` openai/whisper-tiny.en \
1. `--task` transcription

```bash
# Terminal 1
# Install the huggingface cli
pip install -y huggingface_hub tree

# Download tiny-whisper.en locally
huggingface-cli download openai/whisper-tiny.en --local-dir walk/vllm/ubuntu/whisper-tiny.en --local-dir-use-symlinks False --repo-type model

# Ensure the whisper-tiny.en directory is next to your Dockerfile
tree ubuntu

# Build it
podman build -t vllm-whisper-embedded -f walk/vllm/ubuntu/Dockerfile.embedded walk/vllm/ubuntu/

# Run it
podman run --rm -it \
  --security-opt=label=disable \
  --device nvidia.com/gpu=all \
  -p 8000:8000 \
  -v ~/.cache/huggingface:/root/.cache/huggingface:Z \
  vllm-whisper-embedded \
  --model /models/whisper-tiny.en \
  --served-model-name openai/whisper-tiny.en \
  --task transcription \
  --dtype=half

# Terminal 2
# Test it
curl http://localhost:8000/v1/audio/transcriptions \
  -X POST -H "Content-Type: multipart/form-data" \
  -F file=@sample/harvard.wav \
  -F model=openai/whisper-tiny.en

# Terminal 2 output
# {"text":" The stale smell of old beer lingers. It takes heat to bring out the odor. A cold dip restores health and zest. A salt pickle tastes fine with ham. Tacos al pastor are my favorite. A zestful food is the hot cross bun."}

# Terminal 1 output
# ...
# INFO:     127.0.0.1:43702 - "POST /v1/audio/transcriptions HTTP/1.1" 200 OK
# INFO 05-12 20:01:19 [metrics.py:486] Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 5.4 tokens/s, Running: 0 reqs, Swapped: 0 reqs, Pending: 0 reqs, GPU KV cache usage: 0.0%, CPU KV cache usage: 0.0%.
# ...
```

---

## Generation

Explanation of Tasks:

1. Chat → Conversational agents, dialogue systems
1. Instruction → Follows user prompts, task-specific
1. Summarization → Text summarization, document compression
1. Reasoning → Multi-step logic, Q&A, problem-solving
1. Multilingual → Supports multiple languages

---

## Review supported vLLM models [here](https://docs.vllm.ai/en/latest/models/supported_models.html#list-of-text-only-language-models)

The shortlist meets these criteria:

1. top-ranked models from the Hugging Face LLM leaderboard that
2. [are supported by vLLM](https://github.com/vllm-project/vllm/tree/main/vllm/model_executor/models)
3. fit under ~14.5 GiB

| **Model** | **Approx. Parameters** | **Main Task(s)**| **Why It Fits on T4** |
| ---------------------------------- | ---------------------- | --------------------------------------- | -------------------------------------------------- |
| TinyLlama/TinyLlama-1.1B-Chat-v1.0 | 1.1B                   | Chat, generation                        | Tiny, easily fits with full KV caches              |
| Phi-2                              | 2.7B                   | General reasoning, math, code           | Small, \~5–6 GiB in FP16                           |
| Phi-3 Mini (Hugging Face release)  | 3.8B                   | General-purpose generation, chat        | Efficient, \~7–8 GiB in FP16                       |
| Qwen2.5-0.5B                       | 0.5B                   | Chat, generation, general LLM tasks     | Lightweight, fits with margin                      |
| Qwen2.5-1.8B                       | 1.8B                   | Chat, reasoning, generation             | Small size, under \~10 GiB with half precision     |
| LLaMA-2-7B                         | 7B                     | Chat, generation, instruction following | Tight but works with --dtype=half, low batch sizes |
| LLaMA-3-8B                         | 8B                     | Chat, general-purpose generation        | Fits with reduced cache or low concurrency         |
| Mistral-7B-Instruct                | 7B                     | Instruction-following, chat             | Runs on T4 with half precision + tuning            |
| Mixtral-8x7B (2 experts active)    | 12B active (2x7B)      | Mixture-of-experts: chat, reasoning     | Activates only 2 experts; memory footprint \~7B    |

---

### Loading the model at runtime with vLLM on GPU

```bash
# Terminal 1
# Run it
podman run --rm -it \
  --security-opt=label=disable \
  --device nvidia.com/gpu=all \
  -p 8000:8000 \
  docker.io/vllm/vllm-openai \
  --model TinyLlama/TinyLlama-1.1B-Chat-v1.0 \
  --dtype=half \
  --gpu-memory-utilization 0.7

# Expected output
# ...
# INFO:     Started server process [1]
# INFO:     Waiting for application startup.
# INFO:     Application startup complete.
```

```bash
# Terminal 2
# Prompt the model Hello, TinyLlama! How are you today?
curl http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
        "model": "TinyLlama/TinyLlama-1.1B-Chat-v1.0",
        "messages": [
          {"role": "user", "content": "Tell me about Red Hat?"}
        ]
      }'

# response sample
# {"id":"chatcmpl-fe19985ece584222ab12376a73a71325","object":"chat.completion","created":1747102800,"model":"TinyLlama/TinyLlama-1.1B-Chat-v1.0","choices":[{"index":0,"message":{"role":"assistant","reasoning_content":null,"content":"Red Hat (NYSE: RHT) is a global provider of enterprise open source solutions, using a community-powered approach to deliver high-performing technologies that help manage and install Linux, mainframe, cloud, and hybrid cloud environments. Led by a global leader team that provides customers with the best technical support, Red Hat operates under the business principles of unparalleled customer success, community love, and responsible innovation. As an open source-friendly company, Red Hat operates as a community-powered board made up of technical experts, each contributing their specific areas of expertise to the Red Hat Open Source Foundation (OFO). This means they monitor compliance with open source business models, work towards specific goals and policies, and contribute their community expertise with passionate coopereness towards Red Hat's initiatives from strategic and business standpoint. Red Hat's products and services are built on the operating system technology of the Linux Foundation's Linux Foundation Linux Foundation Linux Foundation. With over 30,000 customers and 300 partners across 180 countries, the company is a software industry leader driving necessary technological solutions to power, enable and simplify online business.\n\nKey Benefits of Working with Red Hat:\nRed Hat provides comprehensive cloud-enabled computing solutions, helping customers transform their IT initiatives and create digitally enabled businesses. Some of the key benefits include:\n\n1. Comprehensive Cloud Portfolio: Red Hat delivers the industry's largest portfolio of cloud-native applications and services that power cloud applications.\n\n2. Scalable Platform: Ensures the fastest speed for development and deployment while enabling customers to create scalable cloud-native solutions with innovative intelligence solutions.\n\n3. Enterprise-Grade Service: Providing state-of-the-art security, resiliency, and stability-model solutions to help optimize provider migration in all environments.\n\n4. Enhanced Power to Boost Business Growth: Provides enterprise-class, scalable and secure cloud computing and IoT solutions for maximum business growth.\n\n5. End-to-end Digitalization: Enhances business transformation with the technology and infrastructure alongside key digital services to accelerate journey towards digital.\n\nReasons to Choose Red Hat:\n\n1. Open Source Provides Workaround: Provides a community-backed ongoing support based on open source.\n\n2. Stay Directly on the Open Source Framework: With the advantage of immediacy, Red Hat helps companies remain up-to-date with latest releases based on Open Source technologies.\n\n3. Industry-First EULA: Red Hat Legal guaranteeing its customers' and partners’ EULA allowing them to do as per open standards.\n\n4. Comprehensive Software Development: Red Hat provides the inclusive support for software development as world-renowned open-source community.\n\n5. Product Requests and Reviews Support: Red Hat is the trusted source for reviewing, maintaining, and supporting its software, ensuring nothing falls down to manufacturing.\n\nRed Hat and Its Technological Solutions:\n\nHere are some of Red Hat's technological solutions:\n\n1. OpenShift Container Platform: An open-source container delivery system, available in two editions providing containers and Kubernetes support.\n\n2. Open Storage Solutions: Offers Ironic, Ceph-based storage, fault tolerance and scale for burgeoning IT infrastructure.\n\n3. Red Hat OpenStack Platform: The industry leading OpenStack software solution supports labor, available on-demand to deliver a secure cloud.\n\n4. Red Hat Open Source Center: Offers an interactive and easy-to-use, access optimized marketplace, providing customers the chance to buy and hang with supported and ready-made open-source applications.\n\nIn conclusion, Red Hat, a leading provider of enterprise open source solutions, operates under the sole-setting of a community-powered board, where technical experts contribute their critical expertise in specific community domains with a vision to unite the technologies and deliver unmatched technological solutions and services. With its core and diverse products, enabling open-source innovation, it operates as a distinct innovation force to be reckoned with. Red Hat's comprehensive ecosystem of cloud-native applications, such as OpenShift, OpenStack, Red Hat Enterprise Linux, Red Hat middleware, builds distinct business value for companies in various industry domains.","tool_calls":[]},"logprobs":null,"finish_reason":"stop","stop_reason":null}],"usage":{"prompt_tokens":23,"total_tokens":997,"completion_tokens":974,"prompt_tokens_details":null},"prompt_logprobs":null}
```

This container addresses the following:

1. Serves a model with vllm
1. Uses FastAPI to expose an OpenAI-compatible API
1. Accepts inference requests on port 8000
1. Is connected download the model from Hugging Face at runtime --model TinyLlama/TinyLlama-1.1B-Chat-v1.0

### Loading the model at runtime with vLLM on CPU

```bash
podman run --rm -it \
  -p 8000:8000 \
  docker.io/vllm/vllm-openai \
  --model TinyLlama/TinyLlama-1.1B-Chat-v1.0 \
  --device cpu \
  --dtype float32 \
  --disable-async-output-proc

# Expected output
# TypeError: unsupported operand type(s) for +: 'int' and 'NoneType'
# ...
# RuntimeError: Engine process failed to start. See stack trace for the root cause.
```

`self.max_seq_len_to_capture` is None, and vLLM tries to add it to an int. This is an internal bug where the CPU logic path doesn't initialize all config values properly — especially when using the older fallback engine (V0), which we hit due to:

- `--device cpu`
- `--disable-async-output-proc`
- `--worker-cls vllm.worker.worker.Worker`

**So is CPU support broken?**
Yes — as of v0.8.5.post1, vLLM's CPU support is incomplete and unstable, especially for models like TinyLlama, and:

- V1 Engine doesn’t yet support CPU
- V0 Engine is legacy and mostly tuned for GPU logic
- Many configurations (like memory size, block manager, etc.) are not correctly initialized on CPU fallback