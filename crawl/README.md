# Crawl

"Crawl" represents the early experimentation stage — running Whisper and Faster-Whisper models in containers on a single GPU/CPU instance. This phase begins with open-source Ubuntu containers and ends with supported UBI9-minimal container images.

## Crawl Procedure

1. **Provision a RHEL VM with GPU support** - [Provision RHEL with GPU](RHEL_GPU.md)

2. **Test OpenAI Whisper** - [Ubuntu](/crawl/openai-whisper/ubuntu/README.md)

3. **Test OpenAI Whisper** - [UBI9-minimal](/crawl/openai-whisper/ubi/README.md)

4. **Walk onto OpenAI Whisper onto OpenShift** - [Walk](../walk/README.md)

| ← [Back: Main Readme](../README.md) | [Next: Provision RHEL VM w/GPU →](../../../walk/README.md) |
|-----------------------------------------------|--------------------------------------------------------------------|