# Speech to Text Analysis Whitepaper

This project evaluates various Speech-to-Text (STT) configurations for both streaming and batch (offline) transcription, testing different model variants, container environments, model serving frameworks, deployment platforms, and hardware configurations.

## Goal

1. Demonstrate how to move from individual experimentation to operational enterprise scale.
1. Gather data to answer technical questions regarding performance, security and efficiency along this process.

## Scenarios

- Speech Recognition Models: 3
- Embedded Inference Microservices / Images: 3
- Platforms: 2
- Model Servers: 3
- CPU Types: 4
- GPU Types: 4
- CMD Types: 2

Test 3x general-purpose speech recognition models:

1. Whisper
1. Faster-Whisper
1. NVIDIA Riva

Test Embedded inference microservices on 3x images:

1. Ubuntu
1. UBI9-platform
1. UBI9-minimal

Test on 2x platforms:

1. Linux
1. Kubernetes

Test with 3x Decoupled model servers:

1. vLLM
1. Speaches
1. NVIDIA Triton

Test on 4x CPU:

1. T4
1. L4
1. A10
1. H100

Test on 4x GPU:

1. Intel Cascade Lake
1. Graviton3
1. AMD EPYC
1. Intel Sapphire Rapids

Test with different parameters:

1. default
1. optimized

Provided input files:

1. (Harvard.wav)[https://www.kaggle.com/datasets/pavanelisetty/sample-audio-files-for-speech-recognition]
1. (JFK Inaugural Address from Jan. 20, 1961)[https://www.jfklibrary.org/asset-viewer/archives/jfkwha-001]
1. (JFK Rice University from Sept. 12, 1962)[https://www.jfklibrary.org/asset-viewer/archives/usg-15-29-2]

Provided ground truth transcriptions:

1. Harvard.txt
1. JFK Inaugural Address from Jan. 20, 1961 transcript from the White House
1. JFK Rice University from Sept. 12, 1962 transcript from the White House

### Crawl

Go to the [Crawl README](./crawl/README.md)

### Walk

Go to the [Walk README](./walk/README.md)

### Run

Go to the [Run README](./run/README.md)

## Related resources

- https://github.com/pmichaillat/latex-paper
- https://tex.stackexchange.com/questions/101717/converting-markdown-to-latex-in-latex#246871
