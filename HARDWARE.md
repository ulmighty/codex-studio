# FaceTrace Hardware Sizing Guidance

FaceTrace processes high-resolution video, multichannel audio, and large vector indexes entirely offline. Capacity planning is therefore crucial before onboarding production workloads. This guide summarises recommended footprints for the three most common deployment tiers and highlights knobs that keep the stack deterministic and thermally safe.

## General Principles
- Prefer workstations and servers with dedicated NVIDIA GPUs that support CUDA 12.x for accelerated vision and Whisper workloads.
- Allocate fast NVMe storage for scratch space and FAISS shards; use encrypted SSDs when handling sensitive evidence.
- Pin BIOS/firmware versions and disable auto-updates so inference timing stays reproducible across runs.
- Keep power headroom above 20% to avoid throttling during long-lived indexing jobs.

## Reference Build Profiles
### 1. Developer Workstation
| Component | Recommendation | Notes |
| --- | --- | --- |
| CPU | 8-core/16-thread (Ryzen 7, Intel i7) | Enables concurrent CLI runs, API server, and local UI builds. |
| GPU | RTX 3060 (12 GB) or RTX A2000 (12 GB) | Supports Whisper medium models and 4K vision inference batches. |
| RAM | 32 GB DDR4/DDR5 | Reserve 12 GB for Python processes, 8 GB for Node, remainder for caches. |
| Storage | 2 TB NVMe (split into OS + 1 TB scratch) | Scratch volume should sustain 3 GB/s sequential throughput. |
| Network | Isolated LAN only | No WAN routing; rely on offline mirrors. |

### 2. QA / Integration Lab Node
| Component | Recommendation | Notes |
| --- | --- | --- |
| CPU | 16-core/32-thread (Ryzen 9, Intel i9) | Supports concurrent smoke suites and synthetic load tests. |
| GPU | RTX 4080 16 GB or A5000 24 GB | Necessary for running Whisper large-v2 plus batched vision pipelines. |
| RAM | 64 GB | Allows multiple Docker/venv sandboxes plus FAISS rebuilds. |
| Storage | 4 TB NVMe (RAID1 or mirrored) | Maintain separate volume for test fixtures and generated artifacts. |
| Network | 10 GbE LAN (air-gapped) | Facilitates fixture replication between QA nodes. |

### 3. Production Cell (Per Active Investigator Pod)
| Component | Recommendation | Notes |
| --- | --- | --- |
| CPU | Dual-socket 24-core/48-thread Xeon or EPYC | Schedules ingestion, indexing, and streaming analytics without contention. |
| GPU | 2 x RTX 6000 Ada (48 GB) or L40S | Provide redundancy and sufficient VRAM for multi-stream inference. |
| RAM | 128 GB ECC | Protects against bit-flips; allocate 32 GB per inference pipeline plus OS overhead. |
| Storage | 8 TB NVMe (Tier 1) + 32 TB SATA (Tier 2) | NVMe for hot media/indexes; SATA array for archival snapshots. |
| Network | 25–40 GbE fabric | Required for rapid replication between secure pods and analyst clients. |
| Power/Thermal | Dual PSUs, front-to-back airflow | Prevents throttling and meets datacentre redundancy requirements. |

## GPU Memory Budgeting
- **Vision pipelines**: Reserve ~1.5 GB per 1080p stream when using FP16 detectors; add 0.5 GB for embedding networks.
- **Whisper transcription**: Tiny/Base models require ~1 GB; Medium requires 5–6 GB; Large v3 expects 10 GB. Plan GPU assignment so Whisper and vision jobs do not overcommit VRAM.
- **FAISS builds**: CPU-bound but benefit from 32+ GB RAM for large shards; consider GPU-accelerated FAISS only if VRAM remains >6 GB free after inference workloads.

## Storage Planning
- Maintain at least 3× the size of incoming media as temporary workspace for decoded frames and audio buffers.
- Use separate filesystem mounts for `models/`, `indexes/`, and scratch directories to simplify auditing and wiping procedures.
- Snapshot `indexes/faiss` after every release and mirror the snapshots to an encrypted offline vault.

## Monitoring Hooks
- Connect `projects/FacialRecog/apps/api/app/services/device_manager.py` to vendor-specific telemetry (NVIDIA SMI, lm-sensors) and export metrics to the QC Guardrail dashboard.
- Trigger alarms when GPU utilisation exceeds 95% for >10 minutes or when NVMe temperature surpasses vendor guidelines (typically 70°C).

## Scaling Strategies
- **Horizontal scaling**: Deploy additional pods, each with its own FAISS shard replica, then federate search results at the API layer.
- **Vertical scaling**: Increase GPU count and VRAM when analysts demand real-time Whisper large inference or multi-camera ingestion.
- **Cold storage**: Archive processed media to offline tape libraries or WORM storage after the retention period defined by policy.

For capacity review sessions, log benchmark results in `perf/reports/` and cross-reference them with the hardware profile used. This keeps future procurement aligned with reproducibility requirements.

