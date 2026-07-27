# Grok Hardware Optimization Research Prompt

Attach or paste `README.md` with this prompt.

```text
Act as a senior Linux workstation architect, PCIe topology specialist, storage engineer, and local-AI infrastructure optimizer.

I’ve attached a full specification/configuration snapshot of my Arch Linux + Omarchy workstation. Analyze it deeply and design the best ways to extract more performance, capability, reliability, and utility from the machine.

Important distinction:
- Currently installed: Ryzen 9 9950X, RTX 5070 12 GB, 2× WD_BLACK SN8100 1 TB NVMe, 30/32 GB RAM, Btrfs, Docker, CUDA, Ollama, local AI/agent workloads.
- Spare hardware available: 1× Radeon RX 6600 XT and 2× WD_BLACK SN750 NVMe drives.
- Do not confuse the spare SN750 drives with the installed SN8100 drives.

My workloads include:
- Local LLM inference and AI-agent orchestration
- Software development across Rust, TypeScript, Go, and containers
- Compiling, testing, and running parallel agents
- Desktop use, browsers, media, recording, and occasional creative workloads
- Experimentation with VMs, GPU passthrough, distributed services, and self-hosting

Optimization axes:
1. Real-world performance
2. Local-AI throughput and concurrency
3. Developer productivity
4. Storage reliability and recoverability
5. Useful employment of spare hardware
6. Power draw, heat, noise, and idle efficiency
7. Complexity and maintenance burden
8. Cost-to-benefit ratio
9. PCIe lane and bandwidth constraints
10. Future upgrade flexibility

Investigate the RX 6600 XT options honestly. Do not assume that NVIDIA CUDA and AMD ROCm workloads can pool VRAM or accelerate one model together. Evaluate:

- Installing it as a second desktop/compute GPU
- Driving the desktop from the 6600 XT while reserving the RTX 5070 for CUDA/LLMs
- ROCm compatibility and practical limitations for this exact AMD GPU
- Running independent inference or media workloads on each GPU
- Vulkan-based inference
- FFmpeg/OBS encoding or transcoding
- Virtual-machine GPU passthrough using VFIO/IOMMU
- A dedicated Windows, gaming, media, or testing VM
- Container isolation
- Whether PCIe bifurcation, slot wiring, chipset routing, or reduced lane widths would impair the RTX 5070 or NVMe devices
- Power-supply capacity, connector requirements, thermals, airflow, and idle power
- Whether selling the card is objectively better than installing it

Investigate the two spare SN750 drives as well:

- Dedicated project/build/cache/scratch drives
- Docker data-root, container images, build caches, language package caches, or VM storage
- Local model storage for Ollama and other AI runtimes
- Separate database/workspace volumes
- Btrfs RAID1, independent Btrfs filesystems, mdraid, LVM, or ZFS
- Mirrored backup target versus performance-oriented striping
- Snapshot and backup design
- Separating high-write workloads from the OS drive
- PCIe adapter-card options and required motherboard bifurcation support
- Chipset bandwidth contention
- TRIM, mount options, compression, discard policy, queue scheduler, firmware, SMART monitoring, and thermal throttling
- Expected performance limitations because the SN750 is PCIe Gen3
- Whether USB enclosures, a NAS, or a separate server would be a better use

First, infer as much as possible from the attached machine report. Clearly label any facts that still require motherboard manual, PSU model, drive capacity, available slots, or direct measurement. Do not block the analysis on missing details: provide conditional recommendations for each likely topology.

Required output:

1. Executive verdict
   - The single best configuration
   - Why it wins
   - Main tradeoffs

2. Current-system bottleneck analysis
   - Rank bottlenecks by actual likely impact
   - Separate measured facts from assumptions

3. RX 6600 XT decision matrix
   - Option
   - Benefit
   - Compatibility
   - Performance impact
   - Power/thermal impact
   - Complexity
   - Recommended or rejected
   - Evidence/reasoning

4. SN750 decision matrix
   - Compare at least five layouts
   - Include failure behavior, backup implications, expected performance, and maintenance burden

5. PCIe topology analysis
   - Explain likely CPU versus chipset lane allocation
   - Identify where lane sharing or bifurcation may occur
   - State exactly what motherboard/manual information would confirm it
   - Warn if any proposal might reduce the RTX 5070 link width

6. Three complete build plans
   - Conservative: lowest risk and maintenance
   - Performance: maximum useful throughput
   - Experimental: VM passthrough, split-GPU compute, or homelab architecture

7. Pareto ranking
   Score each plan from 1–10 for:
   - Performance
   - AI utility
   - Reliability
   - Power efficiency
   - Simplicity
   - Cost efficiency
   - Reversibility

8. Implementation plan for the winning option
   - Physical installation order
   - BIOS/UEFI settings
   - Arch Linux packages and drivers
   - Filesystem/storage setup
   - Mount layout
   - Service changes
   - Docker/Ollama changes
   - Monitoring and rollback
   - Exact commands where safe
   - Never include destructive disk commands without highly visible placeholders and warnings

9. Benchmark plan
   Establish a baseline and after-change comparison using:
   - fio
   - SMART/NVMe telemetry
   - PCIe link-width checks
   - GPU idle/load power
   - LLM tokens/sec and concurrent inference
   - Compile/build workloads
   - Docker image/build performance
   - Temperatures and throttling

10. Final recommendation
   - What to install
   - What not to install
   - What to sell or repurpose
   - Which upgrade should happen next
   - The first three actions I should take

Be opinionated and technically rigorous. Reject clever configurations whose complexity, power consumption, or reliability cost exceeds their practical benefit. Prefer measured, reversible improvements. Cite current documentation or credible technical sources for hardware compatibility and any claim that could have changed recently.
```
