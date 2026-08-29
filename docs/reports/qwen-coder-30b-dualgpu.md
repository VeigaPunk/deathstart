# Runbook: Qwen3-Coder-30B-A3B-Instruct on plazir27 with llama.cpp

- **Round:** `qwen-coder-30b-dualgpu`
- **Date:** 2026-08-29
- **Scope:** Serve `Qwen/Qwen3-Coder-30B-A3B-Instruct` (30.5B total / 3.3B active MoE) on `plazir27` via llama.cpp, covering today's single RTX 5070 and the future RTX 5070 + RTX 3090 setup.
- **Evidence class:** `mixed — live probes + cited web sources`
- **Publication state:** reviewed (1 round), provisional pending live verification.

## Axes

1. Correctness of install commands and `llama-server` invocations.
2. Honest performance claims — measured anchors only, estimates labeled.
3. Solo (Profile A) and dual-GPU (Profile B) coverage with a hard gate on 3090 seating.
4. Workstation safety: VRAM headroom, `earlyoom`, swappiness, PSU budget, thermals.
5. Reproducibility: pinned sources, exact sizes, unit files, verification gates.
6. Clear separation between today's reality and the 2026-08-20 README snapshot.

## Reality check

- The 2026-08-20 README's Local-AI section is a snapshot; the ollama stack (`ollama-hvm.service`, `xbreed-hvm-proxy.service`, `gemma4-hvm:official-q4`) is **no longer present**.
- The RTX 3090 24 GB has been **purchased but is NOT seated**.
- **Gate:** `nvidia-smi -L` must list two GPUs before Profile B applies.
- **Profile A — today:** IQ2_M GGUF, ctx 32,768, single RTX 5070 12 GB, `--split-mode none`, `--parallel 1`, q8_0 KV.
- **Profile B — after seating:** Q6_K GGUF, ctx 131,072, RTX 5070 12 GB + RTX 3090 24 GB, `--split-mode layer`, approximate `--tensor-split 2,3`.

## Model facts

| Attribute | Value |
|---|---|
| Model | `Qwen/Qwen3-Coder-30B-A3B-Instruct` |
| Architecture | 30.5 B total / 3.3 B active MoE, 48 layers, 128 experts (8 active/token) |
| Native context | 262,144 tokens |
| License | Apache-2.0 |
| Release date | 2025-07-31 |
| llama.cpp support | `qwen3moe` since build `b5092` (2025-04-09) |

## GGUF sizes

The official Qwen GGUF repo was unreachable at authoring time (HTTP 401), so the table uses `bartowski/Qwen_Qwen3-30B-A3B-GGUF` sizes (identical architecture); Coder sizes are assumed "same tensor shapes, ~equal".

| Quant | Size (bytes) | Size (GiB) | Profile | Notes |
|---|---|---|---|---|
| IQ2_M | 10,430,210,720 | ~9.71 | A | Only quant fitting fully on the solo 12 GB 5070 |
| IQ3_XXS | 12,216,984,224 | ~11.38 | — | Borderline solo; not used by either profile |
| Q4_K_M | 18,632,184,480 | ~17.35 | — | Single-3090 daily driver, not 5070 |
| Q6_K | 25,104,722,592 | ~23.38 | B | Dual-GPU daily driver (12 GB + 24 GB) |
| Q8_0 | 32,483,932,832 | ~30.25 | — | 30.25 GiB — does not fit either single GPU; only feasible dual-GPU with minimal KV headroom — not recommended. |

## Install

### 1. llama.cpp with CUDA for Ampere + Blackwell

Arch package names vary; build from source for a reliable CUDA binary covering `sm_86` (RTX 3090) and `sm_120` (RTX 5070).

```bash
sudo pacman -S --needed base-devel cmake cuda ninja git
git clone https://github.com/ggml-org/llama.cpp.git ~/llama.cpp
cd ~/llama.cpp
cmake -B build -G Ninja -DGGML_CUDA=ON -DBUILD_SHARED_LIBS=OFF
cmake --build build --config Release -j
mkdir -p ~/.local/bin
cp build/bin/llama-server build/bin/llama-cli ~/.local/bin/
```

`qwen3moe` has been supported since `b5092`, but Blackwell/`sm_120` needs current `master`. With both GPUs seated, `GGML_CUDA` auto-detects architectures; if building before seating the 3090, add `-DCMAKE_CUDA_ARCHITECTURES="86;120a"` so both Ampere and Blackwell are covered.

### 2. Download the official GGUF

The repo may require accepting a license gate, which is why an anonymous request returns 401.

```bash
# Option A: legacy huggingface-cli
pip install --user "huggingface-hub<1.0"
huggingface-cli login
huggingface-cli download Qwen/Qwen3-Coder-30B-A3B-Instruct-GGUF \
  --local-dir /scratch/models/qwen3-coder-30b --include "*IQ2_M*" "*Q6_K*"

# Option B: current hf CLI
pip install --user huggingface_hub
hf auth login
hf download Qwen/Qwen3-Coder-30B-A3B-Instruct-GGUF \
  --local-dir /scratch/models/qwen3-coder-30b --include "*IQ2_M*" "*Q6_K*"
```

After download, list the exact files and copy the exact filenames into the service unit `ExecStart` paths — filenames vary by source; do not assume:

```bash
ls -la /scratch/models/qwen3-coder-30b/
```

## systemd user units

Place in `~/.config/systemd/user/`. Only one unit runs at a time. Both mirror the prior `ollama-hvm.service` pattern: user unit, `Restart=on-failure`, working directory under `/scratch`.

### `qwen-coder.service` — Profile A (solo RTX 5070)

```ini
[Unit]
Description=Qwen3-Coder-30B-A3B-Instruct solo RTX 5070 (Profile A)
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

### `qwen-coder-dual.service` — Profile B (RTX 5070 + RTX 3090)

```ini
[Unit]
Description=Qwen3-Coder-30B-A3B-Instruct dual RTX 5070+3090 (Profile B)
After=network.target

[Service]
Type=simple
WorkingDirectory=/scratch/models/qwen3-coder-30b
Restart=on-failure
RestartSec=5
Environment="PATH=/home/vgpnk/.local/bin:/usr/local/bin:/usr/bin"
ExecStart=/home/vgpnk/.local/bin/llama-server \
  --model /scratch/models/qwen3-coder-30b/Qwen3-Coder-30B-A3B-Instruct-Q6_K.gguf \
  --host 127.0.0.1 --port 8080 --ctx-size 131072 --n-gpu-layers 999 \
  --split-mode layer --tensor-split 2,3 \
  --cache-type-k q8_0 --cache-type-v q8_0 --flash-attn on --parallel 2 --jinja

[Install]
WantedBy=default.target
```

**Flag notes:** `--n-gpu-layers 999` means "all layers". Profile A uses `--split-mode none` to force single-GPU. Profile B uses `--split-mode layer` (the mode that permits quantized KV) with an approximate bandwidth-normalized `--tensor-split 2,3` (936:672 ≈ 2:3, putting the larger share on the 3090); `--main-gpu` is omitted because it only matters for `--split-mode none` or `row`. Verify CUDA device order with `nvidia-smi -L` before enabling. Both profiles use q8_0 KV; if hybrid-model corruption is observed (issue #23717), fall back to f16 KV and re-check VRAM. `--flash-attn on` is required for quantized V cache and saves VRAM. With `--parallel 2` in Profile B, the ctx-size is shared KV memory, so each request gets up to 64K tokens. `--parallel 1` in Profile A dedicates the full context to one request. `--jinja` enables chat template + native tool calling.

## Enable and run

```bash
systemctl --user daemon-reload
# Today:
systemctl --user enable --now qwen-coder.service
# After seating the 3090 and confirming nvidia-smi -L shows two GPUs:
systemctl --user stop qwen-coder.service
systemctl --user disable qwen-coder.service
systemctl --user enable --now qwen-coder-dual.service
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
| Same model with 10 FFN layers on CPU | ~89 t/s gen, ~1,100 t/s prompt | same source |
| Qwen3-Coder-30B-A3B-Instruct Q4_K_M on RTX 5070 Ti, partial offload `-ngl 30` | 118.55 t/s gen | llm-benchmark.de 20260729-032129-8ce95a |
| Dual RTX 3090, 35B-A3B MoE, vLLM TP=2 | 149 t/s gen; TP=2+MTP 225–287 t/s gen | tfriedel/qwen3.6-rtx3090-lab |
| Single RTX 3090 same model: llama.cpp vs vLLM AWQ | llama.cpp 115–133 t/s vs vLLM AWQ 18.6 t/s | same source |

### Estimated ranges for plazir27

| Profile | Expected generation | Expected prefill | Basis |
|---|---|---|---|
| A — IQ2_M solo RTX 5070 | ~60–110 t/s | ~800–1,500 t/s | ESTIMATE; extrapolated from RTX 5070 Ti partial-offload anchor |
| B — Q6_K dual RTX 5070 + RTX 3090 | ~120–180 t/s | ~1,500–3,000 t/s | ESTIMATE; bracketed by single/dual RTX 3090-class anchors for same MoE family |

IQ2_M is aggressive; quality loss is possible. Profile B Q6_K is the intended daily driver once the 3090 is seated.

## Workstation impact

| Resource | Profile A | Profile B |
|---|---|---|
| VRAM pinned | ~11.0 GB / 12 GB on RTX 5070 | ~11 GB / 12 GB on RTX 5070 + ~16.5 GB / 24 GB on RTX 3090 |
| System RAM | ~2 GB | ~2 GB |
| CPU during generation | Near idle | Near idle |
| Power draw | ~250 W | ~250 W + ~350 W = ~600 W |
| PSU headroom | 1000 W JP-cap; plenty | ~60 % sustained load; transients covered |
| Desktop feel | Stutter possible | Likely stutter; pause generation during focus work |

Tuning tips: keep `earlyoom` enabled. `vm.swappiness=100` plus pinned VRAM is fine here because the all-GPU path touches only ~2 GB system RAM, so no swappiness change is needed. Use `sudo nvidia-smi -pl` to cap the 3090 at 300 W or the 5070 at 200 W if thermal/noise limits; consumer cards require root. VRAM math: Profile A ≈ 9.71 GiB weights + ~0.8 GiB q8_0 KV at 32K + ~0.5 GiB CUDA/compute buffer ≈ ~11.0 GiB vs ~11.2 GiB free on the 5070 — it fits with slim headroom; if it OOMs at load, drop to `--ctx-size 24576`. Profile B ≈ 23.38 GiB Q6_K weights split 2:3 (~9.4 GiB / ~14.0 GiB) plus ~3.2 GiB shared q8_0 KV at 131K split 2:3 plus compute buffers; do not raise context size without rechecking `nvidia-smi`.

## Honest runner comparison

- **llama.cpp single-GPU:** wins for ease and throughput on one card (115–133 t/s vs vLLM AWQ 18.6 t/s for the same MoE family). Profile A is the pragmatic solo choice.
- **vLLM dual-GPU:** wins on dual RTX 3090 (149 t/s TP=2, 225–287 t/s with MTP). Once the 3090 is seated, evaluate vLLM TP=2 if concurrent latency matters more than llama.cpp's simplicity.
- **KV cache caveats:** `--split-mode tensor` rejects quantized KV outright. `--split-mode layer` allows it, but issue #23717 reports q8_0/q8_0 corruption on some hybrid models; this runbook uses q8_0 KV in both profiles and falls back to f16 KV if corruption is observed.

## Verification gates

1. **Two-GPU gate (Profile B only):** `nvidia-smi -L` must list two GPUs; if one, Profile B is blocked.
2. **Loaded-model probe:** `curl -s http://localhost:8080/v1/models | jq` — expect JSON containing the model id/filename.
3. **Chat probe:** `curl -s http://localhost:8080/v1/chat/completions -H "Content-Type: application/json" -d '{"model":"qwen3-coder-30b-a3b-instruct","messages":[{"role":"user","content":"hello"}],"max_tokens":16}' | jq '.choices[0].message.content'` — expect non-empty response and HTTP 200.
4. **Service status:** `systemctl --user status qwen-coder.service` (or `-dual`) — expect `Active: active (running)` and no repeated restarts.
5. **VRAM sanity:** `watch -n 1 nvidia-smi` — profile A ~11.0 GB on the 5070; profile B ~11 GB on the 5070 and ~16.5 GB on the 3090.

## Sources

1. `https://huggingface.co/Qwen/Qwen3-Coder-30B-A3B-Instruct/raw/main/README.md` — architecture, context, license, release date.
2. `https://huggingface.co/api/models/Qwen/Qwen3-Coder-30B-A3B-Instruct` — model metadata.
3. `https://github.com/ggml-org/llama.cpp/releases/tag/b5092` — llama.cpp qwen3moe support.
4. `https://huggingface.co/api/models/bartowski/Qwen_Qwen3-30B-A3B-GGUF/tree/main` — GGUF sizes (same arch; Coder sizes assumed same tensor shapes, ~equal).
5. `https://llm-benchmark.de/benchmark/run-20260729-060804-5e123f?field=gpu&lang=en` — RTX 3090 Ti Q4_K_M throughput.
6. `https://www.gilesthomas.com/2026/07/benchmarking-qwen-3-6-35b-moe-rtx-3090` — RTX 3090 same-MoE-family all-GPU vs CPU-offload numbers.
7. `https://llm-benchmark.de/benchmark/run-20260729-032129-8ce95a?lang=en` — RTX 5070 Ti partial-offload anchor.
8. `https://github.com/tfriedel/qwen3.6-rtx3090-lab` — dual/single RTX 3090 vLLM vs llama.cpp comparison.
9. `https://github.com/ggml-org/llama.cpp/blob/master/tools/cli/README.md` — CLI flags.
10. `https://github.com/ggml-org/llama.cpp/blob/master/docs/multi-gpu.md` — multi-gpu splitting and tensor-split semantics.
11. `https://github.com/ggml-org/llama.cpp/blob/master/tools/server/README.md` — server OpenAI compatibility and `--jinja` tool calling.
12. `https://github.com/ggml-org/llama.cpp/issues/23717` — q8_0/q8_0 KV cache corruption report on hybrid models.
13. `/home/vgpnk/Projects/deathstart/README.md` — workstation hardware facts and prior `ollama-hvm.service` pattern.
14. `/home/vgpnk/Projects/deathstart/docs/reports/home-clean-r1-2026-07-28.md` — house report style.
