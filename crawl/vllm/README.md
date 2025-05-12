# Crawling vLLM

[Here is a list of supported models for vLLM](https://docs.vllm.ai/en/latest/models/supported_models.html#list-of-text-only-language-models)

```bash
# search for vllm image
podman search vllm

# check the image base os (example is it ubuntu?)
skopeo inspect docker://docker.io/vllm/vllm-openai | jq '.Labels'

# pull the image
podman pull docker.io/vllm/vllm-openai

# vLLM wont run on CPU
# vLLM was explicitly designed and optimized for GPU environments:
# - CUDA
# - Tensor parallelism
# - Async prefill, batching, and serving
# CPU backend (the so-called V0 engine) exists mainly as a legacy path but lacks key implementations to run modern features, including:
# - Async output processing
# - Server-mode batching
# - FastAPI/OpenAI API support
# So, trying to run vLLM on CPU hits a hard wall at the engine level.

# run the image on GPU

# 1. Get a Hugging Face Access Token
# Go to: https://huggingface.co/settings/tokens
# Click New Token → give it a name (e.g., vllm-access) → generate → copy the token.

# To use the default vLLM model
# 2.1 Go to: https://huggingface.co/meta-llama/Llama-2-7b-chat-hf
# You will see a “Agree and Access” button (if you haven’t already clicked it).
# - Log into Hugging Face with your account.
# - Agree to Meta’s license and usage terms.
# If you skip this, no token permissions will work — your account must be on the approved access list.

# You will have to wait for a review from the repository authors. You can check the status of all your access requests in your settings.

# 2.1 Recommended Open Models (No Approval Required)
# Here’s a short list of models you can directly use with vllm:
# Model Name - Size - Use Case
# mistralai/Mistral-7B-Instruct-v0.2 - 7B - Instruction-tuned, great general chat
# mistralai/Mixtral-8x7B-Instruct-v0.1 - Mixture of Experts (MoE) 8x7B - Fast, powerful, cost-efficient
# NousResearch/Nous-Hermes-2-Mistral-7B-DPO - 7B (Mistral base) - Chat, coding, instruction
# openchat/openchat-3.5-1210 - 7B - Strong chat performance
# mosaicml/mpt-7b-chat - 7B - Commercial-friendly, chat-tuned
# tiiuae/falcon-7b-instruct - 7B - Instruction-tuned Falcon
# TinyLlama/TinyLlama-1.1B-Chat-v1.0 - 1.1B (tiny) - Lightweight chat model

# If you don’t want to deal with tokens or gated access use the last 4

# 3. Provide the Token to the Container
# You can pass the token in two main ways:

# 3.1: Set the HUGGING_FACE_HUB_TOKEN environment variable
# --rm -it - Run interactively and remove the container on exit.
# --security-opt=label=disable - Disables SELinux labeling (needed on some systems for GPU access).
# --device nvidia.com/gpu=all - Gives Podman access to all GPUs via NVIDIA Container Toolkit.
# -p 8000:8000 - Maps port 8000 on your machine to the container’s port 8000.
# -e HUGGING_FACE_HUB_TOKEN - Authentication with your token to use the huggingface model.
# docker.io/vllm/vllm-openai - Pulls the official vLLM image from Docker Hub.
# --model meta-llama/Llama-2-7b-chat-hf - Tells vLLM which model to load (can replace with e.g., mistralai/Mistral-7B-Instruct-v0.2).

# for meta-llama/Llama-2-7b-chat-hf
podman run --rm -it \
  --security-opt=label=disable \
  --device nvidia.com/gpu=all \
  -p 8000:8000 \
  -e HUGGING_FACE_HUB_TOKEN=hf_xxxxxxxxYourTokenHere \
  docker.io/vllm/vllm-openai \
  --model meta-llama/Llama-2-7b-chat-hf

# 3.2: Set the HUGGING_FACE_HUB_TOKEN environment variable
# If you don’t need a full 7B parameter model, try:
# - TinyLlama/TinyLlama-1.1B-Chat-v1.0 (1.1B parameters, fits easily).
# - phi-2 models (Hugging Face open releases).
# https://huggingface.co/mistralai/Mistral-7B-Instruct-v0.2
# The Tesla T4 GPU has ~16GB VRAM, but About ~1–2 GB is used by system and driver processes.
# Large models like OpenChat 3.5 (7B) often need 12–16 GB just to load.
# When you run vLLM, it also preallocates memory for KV caches and batching, which can push it over the edge.
# Note: this reduces how much KV cache is preallocated, but can slightly impact throughput.
# You should Set Environment Variable for CUDA Memory Management avoid fragmentation, especially when loading large models
# ven after:
# 1. --dtype=half
# 2. --gpu-memory-utilization 0.7
# 3. PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True
# …the openchat/openchat-3.5-1210 7B model still exceeds available VRAM because:
# T4 GPUs have ~14.5 GiB effective VRAM after drivers.
# Large models barely fit or don’t fit when loading weights + KV cache + runtime memory.
# vLLM preallocates some extra buffers, adding pressure.
# Recommend switching to a smaller model or change ec2 instance
# In addition the mistral model requires user acceptance.
# - Log in with your Hugging Face account.
# - Click “Agree and Access”.
# --rm -it - Run interactively and remove the container on exit.
# --security-opt=label=disable - Disables SELinux labeling (needed on some systems for GPU access).
# --device nvidia.com/gpu=all - Gives Podman access to all GPUs via NVIDIA Container Toolkit.
# -p 8000:8000 - Maps port 8000 on your machine to the container’s port 8000.
# docker.io/vllm/vllm-openai - Pulls the official vLLM image from Docker Hub.
# --model meta-llama/Llama-2-7b-chat-hf - Tells vLLM which model to load (can replace with e.g., mistralai/Mistral-7B-Instruct-v0.2, openchat/openchat-3.5-1210).
# --dtype=half - vLLM by default tries to run in bfloat16 (bf16) mode for speed. Tesla T4 GPUs do not support bfloat16.
# --gpu-memory-utilization 0.7 - vLLM lets you limit memory usage with

# for openchat/openchat-3.5-1210
export PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True

podman run --rm -it \
  --security-opt=label=disable \
  --device nvidia.com/gpu=all \
  -p 8000:8000 \
  docker.io/vllm/vllm-openai \
  --model TinyLlama/TinyLlama-1.1B-Chat-v1.0 \
  --dtype=half

# Successful output
# ...
# INFO:     Started server process [1]
# INFO:     Waiting for application startup.
# INFO:     Application startup complete.

# Terminal 2
# Testing the API with a Chat Completion - send as role user "Hello, how are you?" to TinyLlama 
curl http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
        "model": "TinyLlama/TinyLlama-1.1B-Chat-v1.0",
        "messages": [{"role": "user", "content": "Hello, how are you?"}]
      }'

# TinyLlama assistant Response with I am doing great! How are you? \n\nresponding to the question with a statement is an example of first-person centered speech. ...
# {"id":"chatcmpl-2fd935bbe655475888b4f0c13c26ac0c","object":"chat.completion","created":1746805409,"model":"TinyLlama/TinyLlama-1.1B-Chat-v1.0","choices":[{"index":0,"message":{"role":"assistant","reasoning_content":null,"content":"I am doing great! How are you? \n\nresponding to the question with a statement is an example of first-person centered speech. It conveys the writer's thoughts and perspective on a particular topic. \n\npeople use first-person centered speech when they share their own personal experiences, emotions, or reflections on current events or relationships. This is common in social media posts, emotional letters, or personal diaries. It enables the speaker to converse and connect with other people, termed as \"I-talk.\"","tool_calls":[]},"logprobs":null,"finish_reason":"stop","stop_reason":null}],"usage":{"prompt_tokens":22,"total_tokens":138,"completion_tokens":116,"prompt_tokens_details":null},"prompt_logprobs":null}
```