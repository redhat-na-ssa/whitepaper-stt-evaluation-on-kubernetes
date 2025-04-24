# Storyline

## Crawl

1. Provision GPU-enabled RHEL VM
    1. Discuss the pain-points of installing and maintaining drivers
    1. Set up a consistent and secure baseline for repeatable experiments
    1. Product lead: Highlight the maintenance burden of drivers (kernel compatibility, secure updates) → Red Hat Operator Lifecycle Manager, NVIDIA Operator, OpenShift AI.
1. Create Ubuntu Dockerfile and embed the model
    1. Discuss common starting point for many data scientists
    1. “Why do users choose Ubuntu? What breaks when moving to UBI?”
    1. Introduce embedding the model and decoupled the model serving definitions
    1. The role of Container Registries versus Model Registries in AI
    1. Product lead: Talk about decoupling model packaging from serving logic → leads into Granite, OpenShift AI, KServe/ModelMesh, vLLM, or Model Registry.
1. "The Experimentation Phase" to draw contrast to later "Scaling" and "Serving" phases.
    1. Data & Model Testing Breakdown
        1. Exploring with Simple data (Harvard) versus Complex data (JFK)
        1. Lead into: Need for representative data — opens door to Data-Centric AI conversations, or integrations with tools like Label Studio, Starburst, Pachyderm, Dataiku, etc.
    1. Ubuntu Containers
        1. Model Sizes & Decompressed Size
            1. Product lead: leads into storage w/ODF and integrations, CI/CD, Package (ACS, Clair) versus Model Scanning (integrations Protect.ai)
        1. Cold vs Warm Start
            1. Product lead: leads to OpenShift Kueue, Caching, OpenShift AI vLLM
        1. Hyperparameters vs Arguments
            1. Product lead: OpenShift Jobs, CronJobs, OAI Pipelines "Experiments", NVIDIA KAI Scheduler, Run:ai, Slinky, etc.
        1. CPU vs GPU
            1. Product lead: capacity planning, Accelerators versus not, instance rightsizing (leads to OpenShift Cluster Monitoring, GPU Operator), NVIDIA Time-Slicing, MIG
    1. UBI Containers
        1. Platform support
            1. Production lead: importance and fog of supportability
        1. Security hardening
            1. lead UBI, rootless
                1. Product lead: OpenShift sandboxed containers, Confidential Containers, rootless Podman, SCCs
        1. Container scanning versus model scanning
            1. Product lead: Advanced Cluster Security, Clair
            1. "Is your AI pipeline secure end-to-end?"
        1. Enterprise support
            1. Product lead: Red Hat Value of Subscription, Opens the door to Red Hat Services, Certified Integrations
    1. The Importance of Scaling
        1. Experimentation
            1. Leads into model tracking, experimentation frameworks (MLflow, OpenShift AI)
        1. Data
            1. validation, versioning, pipelines
        1. Job Scheduling
            1. OpenShift Jobs, Kueue, Ray
        1. Problems > 1 machine
            1. OpenShift scale, node pools
        1. Parallel processing
            1. Leads to GPUs, batch scheduling, NUMA affinity
        1. Moving to a cluster
            1. What moves?, OpenShift, OpenShift AI, Hybrid Cloud, GPU-aware schedulers

## Walk

## Run

## Sprint
