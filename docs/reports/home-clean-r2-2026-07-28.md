# Home cleanup — Round 2 audit report

- **Round:** `home-clean-r2`
- **Date:** 2026-07-28
- **Scope:** bounded cleanup, review, publication, synchronization, and mirror verification under `/home/vhpnk`
- **Publication state:** report-only working-tree addition; this task did not stage, commit, or push

## Round-2 axes

1. Publish reviewed authored deltas without mixing runtime debris.
2. Remove only classified runtime artifacts and measure recovered bytes.
3. Apply reviewer-first bounded corrections before final acceptance.
4. Fast-forward or verify upstream synchronization without rewriting history.
5. Verify user-owned mirror parity and clean 0/0 publication state.
6. Preserve explicit ambiguity, ownership, secret, and destructive-operation defers.
7. Produce a spoof-resistant evidence audit and Pareto disposition.

## ROUND_ROSTER

| Axis | Sublead lane |
|---|---|
| Phase-0 inventory and axis expansion | `the-planner-home-clean-r2` |
| Deathstart safety/publication | `ccs-executor-deathstart-r2` |
| Geohot ledger publication | `ccs-executor-geohot-r2` |
| Opportunity Radar publication | `ccs-executor-opportunity-r2` |
| HVM runtime-ignore/deprecation | `ccs-executor-hvm-r2` |
| Hutter/Musketeer runtime cleanup | `ccs-simplifier-runtime-r2` |
| Snapshot-x/Codex synchronization | `ccs-executor-sync-r2` |
| Reviewer-first correctness gate | `cdx-reviewer-home-clean-r2` |
| Evidence synthesis and audit | `cdx-distiller-home-clean-r2` |
| Round report | `cdx-scribe-home-clean-r2` |

## xask lanes

| Lane | Target | Purpose |
|---|---|---|
| Implementation/publication | `--spark --gs codex` | Make bounded repository-local fixes, run relevant checks, commit, and non-force push only approved paths. |
| Review/correctness | `--gpt55 --gs -e low codex` | Inspect the first publication result, identify concrete blockers, and constrain follow-up fixes. |
| Cleanup/synchronization | `--spark --gs codex` | Classify ignored runtime material, remove only approved debris, and verify fast-forward/upstream state. |
| Synthesis | `--gpt55 --gs -e low codex` | Reconcile evidence, mirror state, defers, and the final Pareto verdict. |

Every delegated prompt inherited Godspeed and ended with `| godspeed` or, for executor prompts, `| godspeed-impl`.

## R2 move execution record

| Repository/action | Durable result | Verification evidence |
|---|---|---|
| `deathstart` | Commits `09ae0e2` and bounded follow-up `d8137fb` pushed. | Guarded scratch provisioning accepts an explicit `/dev/disk/by-id` disk only; negative/static checks, `bash -n`, safety tests, secret scan, and diff checks passed. The follow-up changed archive migration from sudo-sensitive `$HOME` to resolved `TARGET_HOME` and added a sandbox regression test. |
| `geohot-bounty-ledger` | Commits `746d84c` and bounded follow-up `3d8f7b7` pushed. | Removed the untracked 404 download, hardened mutation preconditions/runtime exclusion, and corrected stale audit blocker wording after the underlying chain/retrieval issues were resolved. Tests passed; the worktree publication branch was 0/0. |
| `opportunity-radar` | Commits `f2ff083` and bounded follow-up `926bfbf` pushed. | Runtime artifacts were ignored; reviewed R4 test/report/synthesis changes were published. The follow-up distinguished historical synthesis state from current publication state. Validation, tests, diff checks, and tracked-content secret checks passed. |
| `hvm-gemma4` | Commit `3390b4c` pushed. | Deprecated the `mailbox-bend2` shim and ignored `.xbreed` runtime while preserving the tracked mailbox SSoT. Branch and upstream were 0/0. |
| `snapshot-x` | Clean fast-forward to `55a94cf`. | `master` equals `origin/master` at 0/0; no merge commit or rewritten history was introduced. |
| `codex-titanium` | No content publication required. | Configured upstream verified at 0/0. |
| `hutter-prize` and `the-musketeer` | Removed **8,004,200,659 runtime bytes**. | Deletion remained bounded to classified runtime material; authored and ambiguous files were excluded. |

## Mirror and reviewer gate

- Mirror parity was verified at `3d8f7b7` for both Geohot remotes, `926bfbf` for both Opportunity Radar remotes, and `3390b4c` for both HVM remotes. Deathstart, Snapshot-x, and Codex Titanium matched their configured upstream state recorded above.
- Reviewer-first findings were actionable but bounded: Deathstart used sudo-sensitive `$HOME` for archive migration; Geohot's audit still described already-resolved chain/retrieval issues as blockers; Opportunity Radar blurred historical synthesis-time state with current publication state.
- The corresponding bounded fixes were `d8137fb`, `3d8f7b7`, and `926bfbf`; re-review found no blocker in the accepted move.

## Evidence audit and Pareto verdict

EVIDENCE AUDIT: 7 moves with evidence, 0 moves without, 0 dropped, 0 spoof_flagged

- **audit_hash:** `sha256:636107a4a1cbc5412b0db04393fa7a0d31380fe9e70d5b358166e0493e235f03`
- **Source-map serialization:** `[{"move_id":"R2-M01","source_prefix":"ccs"},{"move_id":"R2-M02","source_prefix":"cdx"},{"move_id":"R2-M03","source_prefix":"cdx"},{"move_id":"R2-M04","source_prefix":"cdx"},{"move_id":"R2-M05","source_prefix":"cdx"},{"move_id":"R2-M06","source_prefix":"cdx"},{"move_id":"R2-M07","source_prefix":"cdx"}]`
- Earlier hashes `56a45b2f…`, `7a375590…`, and `2f179b3b…` were rejected after content-fingerprint, over-aggregation, or source-prefix audit failures.
- **R2-M01 through R2-M07:** **KEEP.** The moves improved destructive-storage safety, publication correctness, mailbox SSoT, synchronization, bounded reclamation, and final correctness without an evidenced regression.
- **Final verdict:** **zero blockers** for accepted Round-2 moves after bounded fixes and verification. Deferred paths below remain outside the accepted moves rather than contradicting that verdict.

## Explicit defers

- `grok-build`: defer rebase/format/test repair and any publication.
- `hyperplan-pcbuild/PLAN.md`: defer authored-plan publication pending audience and ownership review.
- `hutter-prize`: defer all authored or ambiguous files; only classified runtime material was removable.
- `ufo-cli`: defer because its configured cross-project upstream requires explicit target correction and ownership review.
- `Downloads`, model files, and credential-bearing or credential-adjacent material: defer classification, movement, deletion, staging, and publication.

## Epistemic bound

- **One claim:** A zero-blocker verdict for the accepted Round-2 moves is compatible with the listed defers because those paths were explicitly excluded.
- **Rejected alternative:** Reject a blanket home-wide stage/delete/push pass; it would collapse authored, runtime, ambiguous, model, and credential-bearing material into one unsafe action.
