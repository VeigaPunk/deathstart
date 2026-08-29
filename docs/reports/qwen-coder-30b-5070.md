# Runbook: Qwen3-Coder-30B-A3B-Instruct on plazir27 (RTX 5070)

- **Round:** `qwen-coder-30b-5070`
- **Date:** 2026-08-29
- **Scope:** Serve `Qwen/Qwen3-Coder-30B-A3B-Instruct` (30.5B total / 3.3B active MoE) on `plazir27`'s single RTX 5070 12 GB via llama.cpp. A second-GPU variant is kept as an appendix only — no second GPU is owned.
- **Evidence class:** `mixed — live probes + cited web sources`
- **Publication state:** reviewed (2 rounds), provisional pending live verification.

## Axes

1. Correctness of install commands and `llama-server` invocations.
2. Honest performance claims — measured anchors only, estimates labeled.
3. Fit within the solo RTX 5070 12 GB, with the OOM fallback path stated.
4. Workstation safety: VRAM headroom, `earlyoom`, swappiness, thermals.
5. Reproducibility: pinned sources, exact sizes, unit file, verification gates.
6. Clear separation between today's reality and the 2026-08-20 README snapshot.

## Reality check

- Live probes on 2026-08-29: exactly **one** GPU (`nvidia-smi -L` → RTX 5070, 12,227 MiB, ~635 MiB used by the desktop, 250 W limit). **No second GPU is owned or seated.** The 1000 W JP-cap PSU is installed, which means a future second card is already powered for.
- The 2026-08-20 README's Local-AI section is a snapshot; the ollama stack (`ollama-hvm.service`, `xbreed-hvm-proxy.service`, `gemma4-hvm:official-q4`) is **no longer present** — no ollama package, no units, no models on disk.
- No llama.cpp installed; nothing on `PATH`. `/scratch` has 908 GiB free.
- **This runbook's profile:** IQ2_M GGUF, ctx 32,768, `--split-mode none`, `--parallel 1`, q8_0 KV. Fits today.

## Model facts

| Attribute | Value |
|---|---|
| Model | `Qwen/Qwen3-Coder-30B-A3B-Instruct` |
| Architecture | 30.5 B total / 3.3 B active MoE, 48 layers, 128 experts (8 active/token) |
| Native context | 262,144 tokens (capped far lower here by VRAM — see below) |
| License | Apache-2.0 |
| Release date | 2025-07-31 |
| llama.cpp support | `qwen3moe` since build `b5092` (2025-04-09); use current `master` for Blackwell |

## GGUF sizes

The official Qwen GGUF repo was unreachable at authoring time (HTTP 401 — likely a license gate), so the table uses `bartowski/Qwen_Qwen3-30B-A3B-GGUF` sizes (identical architecture); Coder sizes are assumed "same tensor shapes, ~equal".

| Quant | Size (bytes) | Size (GiB) | Fits solo 5070? | Notes |
|---|---|---|---|---|
| **IQ2_M** | 10,430,210,720 | ~9.71 | **Yes** | **This runbook's quant.** Aggressive; quality loss possible |
| IQ3_XXS | 12,216,984,224 | ~11.38 | Borderline | ~11.0 GiB all-in likely OOMs at load; not recommended |
| Q4_K_M | 18,632,184,480 | ~17.35 | No | Needs a second GPU (appendix) |
| Q6_K | 25,104,722,592 | ~23.38 | No | Needs a second GPU (appendix) |
| Q8_0 | 32,483,932,832 | ~30.25 | No | — |

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

The repo may require accepting a license gate, which is why an anonymous request returns 401.

```bash
# Option A: legacy huggingface-cli
pip install --user "huggingface-hub<1.0"
huggingface-cli login
huggingface-cli download Qwen/Qwen3-Coder-30B-A3B-Instruct-GGUF \
  --local-dir /scratch/models/qwen3-coder-30b --include "*IQ2_M*"

# Option B: current hf CLI
pip install --user huggingface_hub
hf auth login
hf download Qwen/Qwen3-Coder-30B-A3B-Instruct-GGUF \
  --local-dir /scratch/models/qwen3-coder-30b --include "*IQ2_M*"
```

After download, list the exact file and copy the exact filename into the service unit `ExecStart` path — filenames vary by source; do not assume:

```bash
ls -la /scratch/models/qwen3-coder-30b/
```

## systemd user unit

Place in `~/.config/systemd/user/`. Mirrors the prior `ollama-hvm.service` pattern: user unit, `Restart=on-failure`, working directory under `/scratch`.

### `qwen-coder.service` — solo RTX 5070

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
  --model /scratch/models/qwen3-coder-30b/Qwen3-Coder-30B-A3B-Instruct-IQ2_M.gguf \
  --host 127.0.0.1 --port 8080 --ctx-size 32768 --n-gpu-layers 999 \
  --split-mode none --cache-type-k q8_0 --cache-type-v q8_0 --flash-attn on \
  --parallel 1 --jinja

[Install]
WantedBy=default.target
```

**Flag notes:** `--n-gpu-layers 999` means "all layers". `--split-mode none` forces single-GPU. q8_0 KV: if corruption is ever observed (issue #23717 reports it on some hybrid models), fall back to f16 KV and drop `--ctx-size` to 16384 to compensate. `--flash-attn on` is required for quantized V cache and saves VRAM. `--parallel 1` dedicates the full context to one request. `--jinja` enables the chat template + native tool calling.

## Enable and run

```bash
systemctl --user daemon-reload
systemctl --user enable --now qwen-coder.service
```

## OpenCode wiring

Provider URL: `http://localhost:8080/v1`

Use OpenAI-compatible `/v1/chat/completions`; native tool calling works because `--jinja` is enabled. Example:

```bash
curl http://localhost:8080/v1/chat/completions -H "Content-Type: application/json" \
  -d '{"model":"qwen3-coder-30b-a3b-instruct","messages":[{"role":"user","content":"hello"}],"temperature":0.80,"top_p":0.95,"max_tokens":1024}'
```

## Performance

### Measured anchors

| Setup | Result | Source |
|---|---|---|
| Qwen3-Coder-30B-A3B-Instruct Q4_K_M on RTX 3090 Ti | 554.75 t/s gen @ 5 concurrent, 7,035 t/s prefill | llm-benchmark.de 20260729-060804-5e123f |
| Qwen3-Coder-30B-A3B-Instruct Thinking variant Q4_K_M on RTX 3090 Ti | 198.76 t/s solo-generation | same source |
| Qwen3.6-35B-A3B (same MoE family) on plain RTX 3090, CUDA, UD-IQ4_NL_XL all-GPU | ~140 t/s gen, >3,300 t/s prompt | Giles Thomas, 2026-07 |
| Qwen3-Coder-30B-A3B-Instruct Q4_K_M on RTX 5070 Ti, partial offload `-ngl 30` | 118.55 t/s gen | llm-benchmark.de 20260729-032129-8ce95a |

No measured public anchor exists for this exact model on a plain RTX 5070 — treat the estimate below as an estimate.

### Expected range for plazir27 (solo 5070, IQ2_M all-GPU)

| Metric | Expected | Basis |
|---|---|---|
| Generation | **~60–110 t/s** | ESTIMATE; extrapolated from the 5070 Ti partial-offload anchor (118 t/s with only 30 layers on GPU — full offload at IQ2_M should land in this band) |
| Prefill | ~800–1,500 t/s | ESTIMATE |
| Context | 32,768 tokens | Hard VRAM cap; native 262K is not reachable on 12 GB |

IQ2_M is an aggressive quant — 2-bit MoE weights can show quality loss on subtle reasoning. If output quality disappoints, the upgrade path is a second GPU (appendix), not a bigger quant on this card.

## Workstation impact (solo)

| Resource | Expected |
|---|---|
| VRAM pinned | ~11.0 GB / 12 GB on the RTX 5070 |
| System RAM | ~2 GB |
| CPU during generation | Near idle (MoE on-GPU is GPU-bound) |
| Power draw | Near the 250 W card limit under sustained generation |
| PSU | 1000 W JP-cap — massively overspecced for one card; headroom already exists for a future second GPU |
| Desktop feel | Terminals/browser fine; expect stutter in OBS, `gpu-screen-recorder`, or gaming while generating — stop the service first |

VRAM math: ~9.71 GiB weights + ~0.8 GiB q8_0 KV at 32K + ~0.5 GiB CUDA/compute buffer ≈ ~11.0 GiB vs ~11.2 GiB free — fits with slim headroom. If it OOMs at load, drop to `--ctx-size 24576`.

Tuning tips: keep `earlyoom` enabled. `vm.swappiness=100` plus pinned VRAM is fine here because the all-GPU path touches only ~2 GB system RAM, so no swappiness change is needed. Generation is memory-bound, so `sudo nvidia-smi -pl 200` costs only a few percent of t/s for meaningfully less heat/noise (consumer cards require root for `-pl`).

## Runner choice

llama.cpp is the right solo runner, full stop: for the same MoE family on a single consumer card it measured 115–133 t/s vs vLLM AWQ's 18.6 t/s (source 8). vLLM only becomes interesting with a second GPU (appendix).

## Verification gates

1. **GPU probe:** `nvidia-smi -L` → exactly one RTX 5070.
2. **Loaded-model probe:** `curl -s http://localhost:8080/v1/models | jq` — expect JSON containing the model id/filename.
3. **Chat probe:** `curl -s http://localhost:8080/v1/chat/completions -H "Content-Type: application/json" -d '{"model":"qwen3-coder-30b-a3b-instruct","messages":[{"role":"user","content":"hello"}],"max_tokens":16}' | jq '.choices[0].message.content'` — expect non-empty response and HTTP 200.
4. **Service status:** `systemctl --user status qwen-coder.service` — expect `Active: active (running)` and no repeated restarts.
5. **VRAM sanity:** `watch -n 1 nvidia-smi` — expect ~11.0 GB used on the 5070.
6. **Speed sanity:** time the chat probe or run `llama-bench` on the same GGUF — expect generation in the ~60–110 t/s band; wildly slower numbers mean partial CPU offload (check the server log for "offloaded" layers).

## Appendix: if a second GPU is ever added

The 1000 W PSU already covers it. With an RTX 3090-class 24 GB card seated (`nvidia-smi -L` must list two GPUs), Q4_K_M (~17.35 GiB) or Q6_K (~23.38 GiB) become fully GPU-resident and the daily-driver quant moves off IQ2_M. Sketch:

- Rebuild or re-verify the llama.cpp binary covers both archs (Ampere `sm_86` + Blackwell `sm_120`; add `-DCMAKE_CUDA_ARCHITECTURES="86;120a"` if building before the card is seated).
- Second unit `~/.config/systemd/user/qwen-coder-dual.service`: `--split-mode layer --tensor-split 2,3` (bandwidth 936:672 ≈ 2:3 puts the larger share on the 3090; `--main-gpu` is ignored under layer split), `--ctx-size 131072 --parallel 2 --cache-type-k q8_0 --cache-type-v q8_0 --flash-attn on`. With `--parallel 2` the ctx-size is shared KV memory, so each request gets up to 64K tokens. Verify CUDA device order with `nvidia-smi -L` before enabling.
- Expected: ~120–180 t/s generation (ESTIMATE; bracketed by the single/dual RTX 3090-class anchors above). Honest runner note: on dual RTX 3090s, vLLM TP=2 measured 149 t/s and 225–287 t/s with MTP for the same MoE family — vLLM *wins* the dual-GPU case, so re-evaluate then.

## Sources

1. `https://huggingface.co/Qwen/Qwen3-Coder-30B-A3B-Instruct/raw/main/README.md` — architecture, context, license, release date.
2. `https://huggingface.co/api/models/Qwen/Qwen3-Coder-30B-A3B-Instruct` — model metadata.
3. `https://github.com/ggml-org/llama.cpp/releases/tag/b5092` — llama.cpp qwen3moe support.
4. `https://huggingface.co/api/models/bartowski/Qwen_Qwen3-30B-A3B-GGUF/tree/main` — GGUF sizes (same arch; Coder sizes assumed same tensor shapes, ~equal).
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
