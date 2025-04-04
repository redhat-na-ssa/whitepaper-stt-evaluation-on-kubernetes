# Crawl

Crawl Speech-to-Text models on CPU and GPU on Linux and OpenShift.

## Crawl procedure

In summary:

1. Provision RHEL - [provision RHEL with GPU](provision_rhel_aws.sh)
1. Test OpenAI Whisper - [build and run Whisper](openai-whisper/README.md)
1. Test Faster-Whisper
1. Test NVIDIA Riva

## Goal

Test 3x Models Architectures (Whisper, Faster-Whisper, Riva):

| **Model** | **Size** | **Parameters** | **VRAM (float32)** | **VRAM (int8)** | **Avg. Transcription Speed (RTF)** | **Notes** |
|-|-|-|-|-|-|-|
| **Whisper tiny** | Tiny | ~39M | ~1 GB | ~0.5 GB | ~32x real-time | OpenAI, multilingual |
| **Whisper base** | Base | ~74M | ~1.5 GB | ~0.75 GB | ~16x real-time | OpenAI, multilingual |
| **Whisper small** | Small | ~244M | ~2.6 GB | ~1.3 GB | ~6x real-time | OpenAI, multilingual |
| **Whisper medium** | Medium | ~769M | ~5.5 GB | ~2.9 GB | ~2x real-time | OpenAI, multilingual |
| **Whisper large-v2 / large-v3** | Large | ~1.55B | ~10 GB | ~4.7 GB | ~1x real-time  | v3 has better accuracy |
| **Faster-Whisper (int8)** | All sizes  | same as above  | —  | 50–60% less | Up to **4x** faster than Whisper | Based on CTranslate2 |
| **Riva Conformer-CTC English (en-US)**  | Large | ~120M | ~<2 GB* | ~<1 GB* | Real-time (low-latency GPU tuned) | Optimized for NVIDIA GPUs  |
| **Riva Mandarin-English Code-Switching** | Large  | ~120M | ~<2 GB*  | ~<1 GB* | Real-time | Trained on 17K hrs code-switched data |
| **Riva Spanish-English Code-Switching** | Large | ~120M | ~<2 GB* | ~<1 GB*  | Real-time | Trained on 20K hrs code-switched data |


Test 2x model serving patterns:

| Embedded Inference Microservice | Decoupled Model Serving |
|-|-|
|Ubuntu|-|
|UBI9 Platform|-|
|UBI9 minimal|-|
|-|vLLM|
|-|Faster Whisper|
|-|NVIDIA Triton/TensorRT|

Test Transcription tasks on CPU and GPUs:

| Instance	| GPU	| CPU | Type | Architecture	| Notes |
|-|-|-|-|-|-|
| g4dn	| T4	| Intel Cascade Lake	| x86	| Cost-effective, older |
| g6	| L4	| AWS Graviton3	|Arm	| Power-efficient, modern, new in 2024 |
| g5	| A10G	| AMD EPYC 7003 (Milan)	| x86	| Balanced performance |
| p5	| H100	| Intel Sapphire Rapids	| x86	| Flagship training | workloads|

Provided input files:

1. Harvard.wav
1. JFK Inaugural Address from Jan. 20, 1961
1. JFK Rice University from Sept. 12, 1962

Provided ground truth transcriptions:

1. Harvard.txt
1. JFK Inaugural Address from Jan. 20, 1961 transcript from the White House
1. JFK Rice University from Sept. 12, 1962 transcript from the White House
