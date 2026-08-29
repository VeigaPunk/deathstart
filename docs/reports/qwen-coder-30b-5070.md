# Runbook: Qwen3-Coder-30B-A3B-Instruct on plazir27 (RTX 5070)

- **Round:** `qwen-coder-30b-5070`
- **Date:** 2026-08-29
- **Scope:** Serve `Qwen/Qwen3-Coder-30B-A3B-Instruct` (30.5B total / 3.3B active MoE) on `plazir27`'s single RTX 5070 12 GB via llama.cpp. A second-GPU variant is kept as an appendix only — no second GPU is owned.
- **Evidence class:** `mixed — live probes + cited web sources`
- **Publication state:** live-verified on plazir27, 2026-08-29 (built, installed, probed at 170 t/s).

## Axes

1. Correctness of install commands and `llama-server` invocations.
2. Honest performance claims — measured first, estimates labeled.
3. Fit within the solo RTX 5070 12 GB, with the OOM fallback path stated.
4. Workstation safety: VRAM headroom, `earlyoom`, swappiness, thermals.
5. Reproducibility: pinned sources, exact sizes, unit file, verification gates.
6. Clear separation between today's reality and the 2026-08-20 README snapshot.

## Reality check

- Live probes on 2026-08-29: exactly **one** GPU (`nvidia-smi -L` → RTX 5070, 12,227 MiB, ~635 MiB used by the desktop, 250 W limit). **No second GPU is owned or seated.** The 1000 W JP-cap PSU is installed, which means a future second card is already powered for.
- The 2026-08-20 README's Local-AI section is a snapshot; the ollama stack (`ollama-hvm.service`, `xbreed-hvm-proxy.service`, `gemma4-hvm:official-q4`) is **no longer present** — no ollama package, no units, no models on disk.
- llama.cpp was built from source and the model downloaded 2026-08-29; the service below is installed, enabled, and was probed live.
- **Deployed profile:** Unsloth UD-IQ2_XXS GGUF, ctx 16,384, `--split-mode none`, `--parallel 1`, q8_0 KV.

## Live verification — 2026-08-29

| Check | Result |
|---|---|
| Build | llama.cpp `master` d7bd3bf, `GGML_CUDA=ON`, sm_120 auto-detected — linked clean |
| Download | `unsloth/Qwen3-Coder-30B-A3B-Instruct-UD-IQ2_XXS.gguf`, 10,333,691,040 bytes (matches repo listing exactly) |
| First boot at `--ctx-size 32768` | **OOM at load** — KV cache allocation of 1,632 MiB failed after weights + buffers (measured KV = ~1.6 GiB/32K, not the estimated 0.8) |
| Boot at `--ctx-size 16384` | `Active: active (running)`, all probes pass |
| VRAM while serving | 11,459 MiB used / 332 MiB free on the 5070 |
| Chat probe (code question, 120 max tokens) | Correct answer, HTTP 200, 199 ms round trip |
| Speed probe (512 max tokens) | **170.06 t/s generation, 743.25 t/s prefill** (server `timings`) |
| OpenCode | provider `qwen-local` added to `~/.config/opencode/opencode.json`; model visible via `opencode models` |

Lesson baked into this document: the KV cache for this model at q8_0 is ~50 KiB/token (1,632 MiB at 32,768 ctx), double the pre-deploy estimate — ctx 16,384 is the working ceiling on the solo 5070, not 32,768.

## Model facts

| Attribute | Value |
|---|---|
| Model | `Qwen/Qwen3-Coder-30B-A3B-Instruct` |
| Architecture | 30.5 B total / 3.3 B active MoE, 48 layers, 128 experts (8 active/token) |
| Native context | 262,144 tokens (capped at 16,384 here by VRAM) |
| License | Apache-2.0 |
| Release date | 2025-07-31 |
| llama.cpp support | `qwen3moe` since build `b5092` (2025-04-09); deployed build is current `master` |

## GGUF sizes

Verified live 2026-08-29: **the official `Qwen/Qwen3-Coder-30B-A3B-Instruct-GGUF` repo does not exist** (404/401 even authenticated — Qwen ships only FP8). `lmstudio-community/Qwen3-Coder-30B-A3B-Instruct-GGUF` exists but tops out at Q3_K_L. **`unsloth/Qwen3-Coder-30B-A3B-Instruct-GGUF`** carries the full UD (Dynamic v3) range and is the source used here.

| Quant | Size (bytes) | Size (GiB) | Fits solo 5070? | Notes |
|---|---|---|---|---|
| **UD-IQ2_XXS** (unsloth) | 10,333,691,040 | ~9.62 | **Yes** | **Deployed.** Dynamic v3 2-bit; quality loss possible |
| UD-IQ2_M (unsloth) | 10,837,007,520 | ~10.09 | Tight | Untested; ~0.5 GiB more than UD-IQ2_XXS |
| IQ2_M (bartowski, base model) | 10,430,210,720 | ~9.71 | Yes | Base Qwen3-30B-A3B only — no Coder GGUF from bartowski |
| UD-IQ3_XXS (unsloth) | 12,848,766,112 | ~11.96 | No | — |
| Q4_K_M | 18,632,186,176 | ~17.35 | No | Needs a second GPU (appendix) |
| Q6_K | 25,104,724,288 | ~23.38 | No | Needs a second GPU (appendix) |
| Q8_0 | 32,483,934,528 | ~30.25 | No | — |

## Install

### 1. llama.cpp with CUDA for Blackwell

Arch package names vary; build from source for a reliable CUDA binary. On the solo 5070, `GGML_CUDA` auto-detects `sm_120`.

```bash
sudo pacman -S --needed base-devel cmake cuda ninja git
git clone https://github.com/ggml-org/llama.cpp.git ~/llama.cpp
cd ~/llama.cpp
cmake -B build -G Ninja -DGGML_CUDA=ON -DBUILD_SHARED_LIBS=OFF
cmake --build build --config Release -j
mkdir -p ~/.local/bin
cp build/bin/llama-server build/bin/llama-cli ~/.local/bin/
```

`qwen3moe` has been supported since `b5092`, but Blackwell/`sm_120` needs current `master`. Verify the binary sees the GPU: `llama-cli --list-devices` (or check the server log line listing CUDA devices).

### 2. Download the GGUF

Source: `unsloth/Qwen3-Coder-30B-A3B-Instruct-GGUF` (verified reachable 2026-08-29; the official Qwen GGUF repo does not exist).

```bash
# Option A: legacy huggingface-cli
pip install --user "huggingface-hub<1.0"
huggingface-cli login
huggingface-cli download unsloth/Qwen3-Coder-30B-A3B-Instruct-GGUF \
  --local-dir /scratch/models/qwen3-coder-30b --include "*UD-IQ2_XXS*"

# Option B: current hf CLI
pip install --user --break-system-packages huggingface_hub
hf auth login
hf download unsloth/Qwen3-Coder-30B-A3B-Instruct-GGUF \
  --local-dir /scratch/models/qwen3-coder-30b --include "*UD-IQ2_XXS*"
```

After download, list the exact file and copy the exact filename into the service unit `ExecStart` path — filenames vary by source; do not assume:

```bash
ls -la /scratch/models/qwen3-coder-30b/
```

Note: `/scratch` is root-owned; create the target dir with `sudo mkdir -p /scratch/models/qwen3-coder-30b && sudo chown -R $USER:$USER /scratch/models` first.

## systemd user unit

Installed at `~/.config/systemd/user/qwen-coder.service`. Mirrors the prior `ollama-hvm.service` pattern: user unit, `Restart=on-failure`, working directory under `/scratch`.

```ini
[Unit]
Description=Qwen3-Coder-30B-A3B-Instruct solo RTX 5070
After=network.target

[Service]
Type=simple
WorkingDirectory=/scratch/models/qwen3-coder-30b
Restart=on-failure
RestartSec=5
Environment="PATH=/home/vgpnk/.local/bin:/usr/local/bin:/usr/bin"
Environment="CUDA_VISIBLE_DEVICES=0"
ExecStart=/home/vgpnk/.local/bin/llama-server \
  --model /scratch/models/qwen3-coder-30b/Qwen3-Coder-30B-A3B-Instruct-UD-IQ2_XXS.gguf \
  --host 127.0.0.1 --port 8080 --ctx-size 16384 --n-gpu-layers 999 \
  --split-mode none --cache-type-k q8_0 --cache-type-v q8_0 --flash-attn on \
  --parallel 1 --jinja

[Install]
WantedBy=default.target
```

**Flag notes:** `--n-gpu-layers 999` means "all layers". `--split-mode none` forces single-GPU. q8_0 KV: if corruption is ever observed (issue #23717 reports it on some hybrid models), fall back to f16 KV and drop `--ctx-size` to 8192 to compensate. `--flash-attn on` is required for quantized V cache and saves VRAM. `--parallel 1` dedicates the full context to one request. `--jinja` enables the chat template + native tool calling.

## Enable and run

```bash
systemctl --user daemon-reload
systemctl --user enable --now qwen-coder.service
```

## OpenCode wiring (deployed)

`~/.config/opencode/opencode.json` carries a `provider` entry:

```json
"qwen-local": {
  "npm": "@ai-sdk/openai-compatible",
  "name": "Qwen Local (llama.cpp 5070)",
  "options": { "baseURL": "http://localhost:8080/v1" },
  "models": {
    "Qwen3-Coder-30B-A3B-Instruct-UD-IQ2_XXS": { "name": "Qwen3 Coder 30B A3B (local)" }
  }
}
```

Select it in the TUI with `/models` → `qwen-local/Qwen3-Coder-30B-A3B-Instruct-UD-IQ2_XXS`, or non-interactively with `opencode run --model qwen-local/Qwen3-Coder-30B-A3B-Instruct-UD-IQ2_XXS`. Native tool calling works because `--jinja` is enabled. Pre-change backup: `opencode.json.pre-qwen-local-20260829.bak`.

Raw API check without OpenCode:

```bash
curl http://localhost:8080/v1/chat/completions -H "Content-Type: application/json" \
  -d '{"model":"Qwen3-Coder-30B-A3B-Instruct-UD-IQ2_XXS","messages":[{"role":"user","content":"hello"}],"temperature":0.80,"top_p":0.95,"max_tokens":1024}'
```

## Performance

### Measured on plazir27 (2026-08-29, this exact setup)

| Metric | Measured |
|---|---|
| Generation | **170.06 t/s** (server `timings.predicted_per_second`, 339-token run) |
| Prefill | **743.25 t/s** (server `timings.prompt_per_second`) |
| Context | 16,384 tokens (32,768 OOMs at KV allocation) |

### External anchors for context

| Setup | Result | Source |
|---|---|---|
| Qwen3-Coder-30B-A3B-Instruct Q4_K_M on RTX 3090 Ti | 554.75 t/s gen @ 5 concurrent, 7,035 t/s prefill | llm-benchmark.de 20260729-060804-5e123f |
| Qwen3.6-35B-A3B (same MoE family) on plain RTX 3090, CUDA, UD-IQ4_NL_XL all-GPU | ~140 t/s gen, >3,300 t/s prompt | Giles Thomas, 2026-07 |
| Qwen3-Coder-30B-A3B-Instruct Q4_K_M on RTX 5070 Ti, partial offload `-ngl 30` | 118.55 t/s gen | llm-benchmark.de 20260729-032129-8ce95a |

The pre-deploy estimate was ~60–110 t/s generation; the measurement came in at 170 t/s — the 5070's full offload plus the MoE's 3.3B active params beat the extrapolation. UD-IQ2_XXS is still an aggressive 2-bit quant: quality loss on subtle reasoning is possible. If output quality disappoints, the upgrade path is a second GPU (appendix), not a bigger quant on this card.

## Workstation impact (solo, observed)

| Resource | Observed / expected |
|---|---|
| VRAM pinned | 11,459 MiB used / 332 MiB free on the RTX 5070 while serving |
| System RAM | ~2 GB (llama-server resident) |
| CPU during generation | Near idle (MoE on-GPU is GPU-bound) |
| Power draw | Near the 250 W card limit under sustained generation |
| PSU | 1000 W JP-cap — massively overspecced for one card; headroom already exists for a future second GPU |
| Desktop feel | Terminals/browser fine; expect stutter in OBS, `gpu-screen-recorder`, or gaming while generating — stop the service first |

VRAM math (measured, not estimated): 9.62 GiB weights + 0.8 GiB q8_0 KV at 16K + ~0.9 GiB CUDA/compute buffer ≈ 11.2 GiB — effectively the whole card. Do not raise ctx without a bigger card; do not run a second GPU-hungry app while serving.

Tuning tips: keep `earlyoom` enabled. `vm.swappiness=100` plus pinned VRAM is fine here because the all-GPU path touches only ~2 GB system RAM, so no swappiness change is needed. Generation is memory-bound, so `sudo nvidia-smi -pl 200` costs only a few percent of t/s for meaningfully less heat/noise (consumer cards require root for `-pl`).

## Runner choice

llama.cpp is the right solo runner, full stop: for the same MoE family on a single consumer card it measured 115–133 t/s vs vLLM AWQ's 18.6 t/s (source 8). vLLM only becomes interesting with a second GPU (appendix).

## Verification gates

1. **GPU probe:** `nvidia-smi -L` → exactly one RTX 5070.
2. **Loaded-model probe:** `curl -s http://localhost:8080/v1/models | jq` — expect JSON containing the model id/filename.
3. **Chat probe:** `curl -s http://localhost:8080/v1/chat/completions -H "Content-Type: application/json" -d '{"model":"Qwen3-Coder-30B-A3B-Instruct-UD-IQ2_XXS","messages":[{"role":"user","content":"hello"}],"max_tokens":16}' | jq '.choices[0].message.content'` — expect non-empty response and HTTP 200.
4. **Service status:** `systemctl --user status qwen-coder.service` — expect `Active: active (running)` and no repeated restarts.
5. **VRAM sanity:** `nvidia-smi --query-gpu=memory.used,memory.free --format=csv` — expect ~11,400 MiB used / a few hundred MiB free.
6. **Speed sanity:** request ~500 tokens and read `timings.predicted_per_second` in the response — expect ~170 t/s; wildly slower numbers mean partial CPU offload (check the server log for "offloaded" layers).
7. **OpenCode sanity:** `opencode models | grep qwen-local` — expect the model listed.

## Appendix: if a second GPU is ever added

The 1000 W PSU already covers it. With an RTX 3090-class 24 GB card seated (`nvidia-smi -L` must list two GPUs), Q4_K_M (~17.35 GiB) or Q6_K (~23.38 GiB) become fully GPU-resident and the daily-driver quant moves off UD-IQ2_XXS. Sketch:

- Rebuild or re-verify the llama.cpp binary covers both archs (Ampere `sm_86` + Blackwell `sm_120`; add `-DCMAKE_CUDA_ARCHITECTURES="86;120a"` if building before the card is seated).
- Second unit `~/.config/systemd/user/qwen-coder-dual.service`: `--split-mode layer --tensor-split 2,3` (bandwidth 936:672 ≈ 2:3 puts the larger share on the 3090; `--main-gpu` is ignored under layer split), `--ctx-size 131072 --parallel 2 --cache-type-k q8_0 --cache-type-v q8_0 --flash-attn on`. With `--parallel 2` the ctx-size is shared KV memory, so each request gets up to 64K tokens. Verify CUDA device order with `nvidia-smi -L` before enabling.
- Expected: ~120–180 t/s generation (ESTIMATE; bracketed by the single/dual RTX 3090-class anchors above). Honest runner note: on dual RTX 3090s, vLLM TP=2 measured 149 t/s and 225–287 t/s with MTP for the same MoE family — vLLM *wins* the dual-GPU case, so re-evaluate then.

## Sources

1. `https://huggingface.co/Qwen/Qwen3-Coder-30B-A3B-Instruct/raw/main/README.md` — architecture, context, license, release date.
2. `https://huggingface.co/api/models/Qwen/Qwen3-Coder-30B-A3B-Instruct` — model metadata.
3. `https://github.com/ggml-org/llama.cpp/releases/tag/b5092` — llama.cpp qwen3moe support.
4. `https://huggingface.co/api/models/unsloth/Qwen3-Coder-30B-A3B-Instruct-GGUF/tree/main` — deployed GGUF size (verified against downloaded file, byte-exact).
5. `https://llm-benchmark.de/benchmark/run-20260729-060804-5e123f?field=gpu&lang=en` — RTX 3090 Ti Q4_K_M throughput.
6. `https://www.gilesthomas.com/2026/07/benchmarking-qwen-3-6-35b-moe-rtx-3090` — RTX 3090 same-MoE-family all-GPU vs CPU-offload numbers.
7. `https://llm-benchmark.de/benchmark/run-20260729-032129-8ce95a?lang=en` — RTX 5070 Ti partial-offload anchor.
8. `https://github.com/tfriedel/qwen3.6-rtx3090-lab` — single/dual RTX 3090 vLLM vs llama.cpp comparison.
9. `https://github.com/ggml-org/llama.cpp/blob/master/tools/cli/README.md` — CLI flags.
10. `https://github.com/ggml-org/llama.cpp/blob/master/docs/multi-gpu.md` — multi-gpu splitting and tensor-split semantics.
11. `https://github.com/ggml-org/llama.cpp/blob/master/tools/server/README.md` — server OpenAI compatibility and `--jinja` tool calling.
12. `https://github.com/ggml-org/llama.cpp/issues/23717` — q8_0/q8_0 KV cache corruption report on hybrid models.
13. `/home/vgpnk/Projects/deathstart/README.md` — workstation hardware facts and prior `ollama-hvm.service` pattern.
14. `/home/vgpnk/Projects/deathstart/docs/reports/home-clean-r1-2026-07-28.md` — house report style.
