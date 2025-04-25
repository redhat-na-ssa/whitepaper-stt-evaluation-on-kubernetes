# Crawl

"Crawl" represents the early experimentation stage — running Whisper and Faster-Whisper models in containers on a single GPU/CPU instance. This phase begins with open-source Ubuntu containers and ends with supported UBI9-minimal container images.

## Crawl Procedure

1. **Provision a RHEL VM with GPU support**  
   [Provision RHEL with GPU](RHEL_GPU.md)

2. **Test OpenAI Whisper**
    - [Ubuntu](/crawl/openai-whisper/ubuntu/README.md)
    - [UBI9-minimal](/crawl/openai-whisper/ubi/minimal/README.md)

NOTE: *[UBI9-platform](/crawl/openai-whisper/ubi/platform/README.md) is used for discussion only*

3. **Test Faster-Whisper** – *coming soon*
    - Ubuntu – *not yet implemented*
    - UBI9-minimal – *not yet implemented*
