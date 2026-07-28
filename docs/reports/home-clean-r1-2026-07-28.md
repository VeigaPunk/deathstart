# Home cleanup — Round 1 audit report

- **Round:** `home-clean-r1`
- **Date:** 2026-07-28
- **Scope:** `/home/vhpnk`, with Git repositories treated independently
- **Evidence class:** `none — documentation`
- **Publication state:** provisional; no staging, commit, or push was performed by this report task

## Axes

1. Generated-clutter reduction and measurable space recovery.
2. Canonical organization of loose home artifacts without broken references.
3. Dirty-repository hygiene and commit-readiness classification.
4. Fetch/upstream/remote synchronization completeness.
5. Safety, secrecy, reversibility, and destructive-operation stop gates.
6. Cross-axis source-of-truth and external-path coherence.
7. Evidence synthesis, spoof resistance, and auditable handoff.

## ROUND_ROSTER

| Axis | Sublead |
|---|---|
| Phase-0 inventory / planning | `the-planner-home-audit` |
| Clutter reduction | `ccs-simplifier-home-r1` |
| Canonical organization | `ccs-executor-organize-r1` |
| Dirty-repository review | `cdx-reviewer-repos-r1` |
| Repository sync audit | `ccs-executor-sync-audit-r1` |
| Safety and reversibility | `cdx-sentinel-home-r1` |
| Cross-axis coherence | `cdx-connector-home-r1` |
| Blinded synthesis / source-map reveal | `cdx-distiller-home-r1` |
| Round report | `cdx-scribe-home-r1` |

## xask targets observed

| Axis | Target | Prompt purpose |
|---|---|---|
| Organization | `--spark --gs codex` | Classify loose home and Downloads artifacts into conservative canonical paths. |
| Repository hygiene | `--gpt55 --gs -e low codex` | Classify dirty/untracked content, ambiguity, secrets, and safe commit groups. |
| Sync | `--spark --gs codex` | Audit fetch/upstream/remotes and identify synchronizable versus deferred branches. |
| Safety | `--gpt55 --gs -e low codex` | Threat-model broad cleanup, commits, and pushes; define stop gates. |
| Cross-axis | `--spark codex` | Identify conflicts among deletion, organization, Git SSoTs, and publication. |

The recorded xask prompts were advisory. The simplifier's deletion decision was supported instead by local ignore/tracking, process-reference, dry-run, size/count, and post-state probes.

## Six HC-R1 moves

| Move | Source prefix | Durable result | Provisional Pareto verdict |
|---|---|---|---|
| `HC-R1-M01` | `ccs` | Removed only ignored `Projects/codex-titanium/codex-rs/target` with `git clean -fdX -- target`: **141,819,450,393 apparent bytes** and **133,543 items** removed (122,118 files + 11,425 directories). Post-state: target absent, repository status/diff clean, `cargo metadata --no-deps` succeeds, and no `target-*` peer was found. | **KEEP.** Large measured recovery with no tracked delta and successful structural verification. |
| `HC-R1-M02` | `ccs` | Consolidated three loose-home artifacts into `deathstart/optimizations/2026-07-27`: removed byte-identical `~/optimize-root.sh`; moved `~/setup-fast-tmp.sh` to `scripts/setup-fast-tmp.sh`; moved `~/X870E_TOMAHAWK_MAX_PERF.txt` to the bundle root; updated only usage comments to canonical paths. Pre/post hashes matched, `bash -n` and `git diff --check` passed, and stale old-path search returned none. | **KEEP, pending commit gate.** Improves organization without content loss; resulting repository delta remains uncommitted. |
| `HC-R1-M03` | `cdx` | Reviewed eight dirty repositories and separated authored candidates from generated/runtime debris and blockers. | **KEEP AS DISPOSITION ONLY.** No bulk stage or publication action is justified yet. |
| `HC-R1-M04` | `ccs` | Fetched 19 writable practical repositories; reported 14 tracked branches at 0/0 and recorded explicit exceptions. The immutable Codex clone fetch failed because it is read-only. | **KEEP AS AUDIT.** Read-only synchronization evidence improves visibility; it does not authorize pushes. |
| `HC-R1-M05` | `cdx` | Blocked execution/commit of Deathstart NVMe provisioning: `setup-fast-tmp.sh` hard-codes destructive `/dev/nvme1n1` operations despite documented enumeration flips; `optimize-root.sh` also contains hard-coded examples. Require explicit device confirmation and a stable by-id target before proceeding. | **KEEP BLOCKER.** Safety improvement; destructive execution remains rejected. |
| `HC-R1-M06` | `cdx` | Marked `grok-build` not commit-ready: branch behind `origin/main` by 1; `cargo fmt --all -- --check` fails in `dispatch/modes.rs`; targeted pager test fails at `lifecycle.rs:1914` (`Some("ask")` versus `Some("auto")`); broader workspace tests did not complete within 120 seconds. | **KEEP DEFER.** Rebase/fix/format/retest before any commit or push. |

## Evidence audit and provenance

Exact evidence audit line:

```text
EVIDENCE AUDIT: 6 moves with evidence, 0 moves without, 0 dropped, 0 spoof_flagged
```

- **audit_hash:** `ed2657cf11520ee9337503a04dbc560ab12f7ed371f426afb5f0174f114d8b05`
- **Source-map serialization:** `[{move_id:HC-R1-M01,source_prefix:ccs},{move_id:HC-R1-M02,source_prefix:ccs},{move_id:HC-R1-M03,source_prefix:cdx},{move_id:HC-R1-M04,source_prefix:ccs},{move_id:HC-R1-M05,source_prefix:cdx},{move_id:HC-R1-M06,source_prefix:cdx}]`
- **Spoof flags:** zero affirmative mismatches. Post-state and file excerpts were independently inspectable. Historical deletion magnitude and the pre-move loose-home state cannot be reconstructed after mutation, so those values retain their contemporaneous probe provenance rather than being relabeled as fresh measurements.

## Contradictions and scope cautions

1. The distiller's initial mailbox drain returned no events even though its brief supplied six current-round returned facts; later durable messages and local post-state supported synthesis.
2. The sync sublead reported 14 tracked 0/0 branches, while a fresh top-level scan found 13. The extra result may be a nested repository; preserve the original source scope until the repository list is reconciled.
3. `/home/vhpnk/Projects` is not a Git root. Every repository disposition and sync result is independent.
4. In `hvm-gemma4`, generated-looking paths can be tracked: 91 tracked paths existed under `analysis/`, `benchmarks/`, and `docs/reports/`. Classification must precede deletion.
5. The tracked `hvm4/mailbox.bend` keep policy, runtime `.xbreed/mailbox/events.ndjson`, and tracked machine-local `local.env` have different authority and retention semantics.

## Organization changes

| Before | After | State |
|---|---|---|
| `/home/vhpnk/optimize-root.sh` | Canonical tracked copy already at `deathstart/optimizations/2026-07-27/scripts/optimize-root.sh` | Loose byte-identical duplicate removed; canonical usage comment corrected. |
| `/home/vhpnk/setup-fast-tmp.sh` | `deathstart/optimizations/2026-07-27/scripts/setup-fast-tmp.sh` | Moved unchanged, then usage comments updated. |
| `/home/vhpnk/X870E_TOMAHAWK_MAX_PERF.txt` | `deathstart/optimizations/2026-07-27/X870E_TOMAHAWK_MAX_PERF.txt` | Moved unchanged. |
| Downloads | No change | Intentionally excluded because model, research, unknown-payload, and existing-project ownership were ambiguous. |

## Dirty-repository dispositions

| Repository | Round-1 disposition |
|---|---|
| `geohot-bounty-ledger` | Discard/ignore `bp_ford.txt` 404 download. If authorized later, commit mutations separately from audit/test corrections. Two-remotes state requires explicit publication target review. |
| `grok-build` | Defer: behind upstream, formatting failure, targeted test failure, and incomplete workspace test run. |
| `hutter-prize` | Ignore `.xbreed` logs and untracked experiment binaries/corpora/archives. No configured upstream, although `main` matched both `github/main` and `gitlab/main` at audit time. |
| `hvm-gemma4` | Treat `hvm4/mailbox-bend2.sh` deprecation as a standalone candidate only after ownership review; do not mix it with cleanup. |
| `hyperplan-pcbuild` | `PLAN.md` is a standalone authored candidate after audience review. |
| `opportunity-radar` | Ignore `.xbreed`, `__pycache__`, and `.pyc`; group report/test/synthesis changes together only after validation and two-remote target review. |
| `the-musketeer` | Ignore runtime `.xbreed` logs; no commit grouping was approved in Round 1. |
| `deathstart` | Keep organization delta pending, but block the NVMe provisioning script from execution/commit until stable device identity and destructive intent are explicitly confirmed. Existing `REPORT.md` changes predated organization work and were not authored by that sublead. |

No staged changes or regex secret signatures were reported in dirty text files. Binary and mailbox artifacts were not content-cleared and therefore remain excluded from publication.

## Sync exceptions

- `grok-build/main`: 0 ahead / 1 behind, dirty.
- `snapshot-x/master`: 0 ahead / 2 behind, clean.
- `ufo-cli/main`: configured to track cross-project `hangar/main` and reported 16/0 there; 0/0 versus `gitlab/main`; 0/1 versus `origin/main`. Defer push because the configured upstream is not a `ufo-cli` target.
- `codex-titanium/root-delta`: no configured upstream; equals `origin/root-delta` at 0/0.
- `hutter-prize/main`: no configured upstream; equals `github/main` and `gitlab/main` at 0/0.
- Immutable Codex clone: detached/read-only; fetch failed by design.
- `xbrd-tui`: local branch name differs from tracked `origin/stage3/rough-tui` despite 0/0.
- Pushes to `HigherOrderCO/HVM4` and `xai-org/grok-build` are deferred pending explicit ownership/permission confirmation.

## Commit delta pending

At the pre-report audit, `deathstart` had no staged paths and this uncommitted delta:

```text
 M optimizations/2026-07-27/REPORT.md
 M optimizations/2026-07-27/scripts/optimize-root.sh
?? optimizations/2026-07-27/X870E_TOMAHAWK_MAX_PERF.txt
?? optimizations/2026-07-27/scripts/setup-fast-tmp.sh
```

Tracked numstat before this report was `52 insertions` in `REPORT.md` and `1 insertion / 1 deletion` in `scripts/optimize-root.sh`; the two organization destinations were untracked. This report is the sole intended Round-1 audit commit; all other repository changes remain pending for Round 2 safety review.

## Epistemic bound

- **One non-obvious claim:** Moving either `hvm-gemma4` or its sibling `HVM4` can leave both repositories Git-clean while breaking execution because `local.env` expresses the dependency as an external filesystem path rather than a Git relationship.
- **One rejected alternative:** Reject blanket generated-file deletion followed by repository-wide stage/commit/push; tracked evidence, runtime mailbox material, destructive scripts, and unrelated authored changes require path-specific classification and gates.
