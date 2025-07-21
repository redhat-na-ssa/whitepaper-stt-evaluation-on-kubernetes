# Storyline

## Crawl

## Crawl Phase: Local to Containerized STT Experimentation

This phase focuses on early-stage experimentation with Speech-to-Text (STT) models in single-node environments — helping data scientists transition from local experimentation to repeatable, containerized workloads.

---

### 1. Provision a GPU-Enabled RHEL VM
- **Why this matters:** Enables consistent, secure experimentation with GPU workloads on RHEL.
- **Talking Points:**
  - Common pain-points: driver installs, kernel compatibility, library mismatches across GPU families.
  - Establish a repeatable and secure baseline.
  - **Product Lead-In:** OpenShift AI, RHEL for AI, Red Hat Operator Lifecycle Manager, NVIDIA GPU Operator.

### 2. Understand Common Data Scientist Starting Points
- **Why local?**
  - Faster iteration: no queueing, immediate feedback.
  - Easier setup: no cluster credentials or infra complexity.
  - Lower cost: avoids cloud billing.
  - Ideal for small models/datasets.
  - Full tooling control and prototyping flexibility.

- **Why migrate to a cluster later?**
  - Scale: memory/compute limits reached.
  - Speed: more parallelism, GPU efficiency.
  - Collaboration: team workflows, reproducibility.
  - Deployment: production-ready serving.
  - Governance: auditing, isolation, secure operations.

- **Where people pause:**
  - Local Dockerfiles, notebooks, serialized models, basic APIs, pipeline scripts.
  - **Product Lead-In:** Introduce the separation between model packaging and serving → s2i, oc new-app, OCP, Quay, Model Registry, Granite, vLLM, KServe.

---

### 3. The Experimentation Phase
- **Purpose:** Build data and model familiarity, evaluate accuracy, performance, and edge cases.
- **Simple vs Complex Data:**
  - **Harvard**: Clean baseline, short form audio.
  - **JFK**: Long form, challenging transcription.
  - **Product Lead-In:** Data-centric AI (Label Studio, Pachyderm, Starburst, Dataiku).

#### Ubuntu Containers
- Why Ubuntu is popular:
  - Community support, wide ML ecosystem.
- Experiments to Run:
  - **Model Sizes & Decompressed Size** → leads to ODF, image storage.
  - **Cold vs Warm Start** → leads to Kueue, caching, OpenShift AI.
  - **Args vs Hyperparams** → leads to Pipelines, KAI Scheduler, CronJobs.
  - **CPU vs GPU** → rightsizing, NVIDIA MIG, scheduling policies.
  - **Product Lead-Ins:** GPU Operator, Cluster Monitoring, Secure Supply Chain.

#### UBI & UBI9 Containers
- **What breaks?** Python libs, apt → microdnf, devtools, SSL.
- **Platform Support:**
  - RHEL/UBI = Supported & Hardened
  - Ubuntu = Best-effort
- **Security:**
  - Trusted Chains, rootless Podman, Sandboxed Containers
  - **Product Lead-In:** ACS, Clair, Confidential Containers
- **Model Scanning vs Container Scanning:**
  - Highlights differences and why both matter.
  - **Lead-In:** Protect.ai, Clair integrations
- **Enterprise Support:**
  - RH Subscription, RH Services, Partner Certifications

---

### 4. Importance of Scaling
- **Why scale beyond the workstation?**
  - Track Experiments: MLflow, OpenShift AI
  - Data Management: pipelines, versioning
  - Schedule Jobs: OpenShift Jobs, Ray, Kueue
  - Larger Problems: Cluster scheduling, node pools
  - Parallel Inference: GPUs, NUMA affinity, batch schedulers
  - **Product Lead-In:** OpenShift AI, hybrid scheduling, OpenShift at scale

---

This Crawl phase sets the stage for transitioning to "Walk" and "Run" — moving from individual tests to scalable, multi-tenant serving platforms.

## Walk

## Run

## Sprint
