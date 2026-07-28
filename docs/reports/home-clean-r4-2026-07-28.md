# Home cleanup — Round 4 cap report

- **Round:** `home-clean-r4`
- **Date:** 2026-07-28
- **Scope:** final narrow runtime-ignore publication, DS4CC boundary audit, and cleanup cap
- **Publication state:** report-only working-tree addition; this task did not stage, commit, or push
- **Cap:** reached; no further cleanup round is authorized by this report

## Round-4 axes

1. Publish and test one exact runtime-mailbox ignore without hiding adjacent evidence.
2. Verify both user-owned Geohot mirrors at one immutable revision.
3. Establish the canonical DS4CC repository boundary without overwriting unique managed-state edits.
4. Reconcile cross-axis claims against repository-specific reviewer evidence.
5. Preserve recoverability, explicit defers, and a spoof-resistant evidence trail.
6. Close the cleanup with measured Round-1-plus-2 reclamation and no destructive follow-on.

## ROUND_ROSTER

| Axis | Sublead lane |
|---|---|
| Phase-0 inventory and axis expansion | `the-planner-home-clean-r4` |
| Geohot narrow-ignore implementation/publication | `ccs-executor-geohot-ignore-r4` |
| DS4CC canonical-boundary reconstruction | `cdx-revenger-ds4cc-r4` |
| Cross-root coherence | `cdx-connector-home-r4` |
| Independent cap review and contradiction resolution | `cdx-reviewer-cap-r4` |
| Evidence synthesis and source-map reveal | `cdx-distiller-home-clean-r4` |
| Cap report | `cdx-scribe-home-clean-r4` |

## xask lanes

| Lane | Target | Purpose |
|---|---|---|
| Geohot implementation | `--spark --gs codex` | Add only the root-anchored mailbox-event ignore, test it, commit it, and non-force push both mirrors. |
| DS4CC reconstruction | `--gpt55 --gs codex` | Compare canonical Work state with managed marketplace and cache state without mutation. |
| Cross-root coherence | `--spark --gs codex` | Test parity claims across roots while retaining repository-specific scope. |
| Review and synthesis | `--gpt55 --gs -e low codex` | Resolve contradictory scope, audit provenance, and cap the accepted frontier. |

Every delegated prompt inherited Godspeed and ended with `| godspeed` or, for executor prompts, `| godspeed-impl`.

## R4 move record and verdicts

| Move | Durable result | Verification evidence | Verdict |
|---|---|---|---|
| `R4-M01` | Geohot commit `5b2256638ef2d3a1b09950204e97e7d00330d8a4` adds only `/.xbreed/mailbox/events.ndjson` and was pushed to both mirrors. | `origin/main`, `github/main`, and local `HEAD` all resolve to `5b22566`; commit-range diff-check passed; `npm test` passed 3/3 plus catalog validation and reproducibility checks. | **KEEP.** Exact runtime hygiene, mirror parity, and tests are evidenced. |
| `R4-M02` | `/home/vhpnk/Work/ds4cc-marketplace` at `e52695a74d6206605fbb664e7bc862dbbcc87e08` is the canonical DS4CC boundary. | Work `HEAD` equals `origin/main`; the managed marketplace is stale and dirty with unique edits, while generated/runtime cache artifacts are mutated. | **KEEP AS BOUNDARY/BLOCKER.** Preserve and reconcile managed deltas; do not refresh, reset, or reinstall. |
| `R4-M03` | Connector comparison contributed a narrow HVM/limited-parity observation. | Its broader DS4CC-parity language conflicted with repository-specific dirty/stale/cache evidence. | **PARTIAL KEEP.** Retain only the scope-supported observation; drop the broad parity claim. |
| `R4-M04` | Independent review validated the Geohot result and confirmed DS4CC divergence. | Reviewer evidence resolved the connector conflict in favor of the scope-matched DS4CC reconstruction and blocked destructive remediation. | **KEEP.** |

## Connector overclaim and reviewer resolution

The connector generalized limited parity into broad DS4CC parity. That overclaim would have made the managed marketplace appear disposable. The reviewer independently confirmed that Geohot was clean and mirrored while DS4CC remained a separate canonical-versus-managed boundary: Work is canonical at `e52695a`, but the managed marketplace is stale/dirty, contains unique edits, and has mutated cache state. Repository-specific evidence therefore prevailed. **One claim was dropped**—the `R4-M03` broad DS4CC parity overclaim—while no move was dropped in full.

## Evidence audit

```text
EVIDENCE AUDIT: 4 moves with evidence, 0 moves without, 0 dropped, 0 spoof_flagged
```

- **audit_hash:** `663096e0468f54f61a8fd24edb15390eb8fbaff8c4ab0115ad1860945cba3401`
- **Canonical source map:** `{"R4-M01":{"revision":"5b22566","source":"geohot","source_prefix":"cdx"},"R4-M02":{"source":"DS4CC recon","source_prefix":"cdx","work_canonical":"e52695a"},"R4-M03":{"source":"connector","source_prefix":"cdx"},"R4-M04":{"source":"reviewer","source_prefix":"cdx"}}`
- **Assessment detail:** 3 moves fully accepted, 1 partially accepted, 0 moves fully dropped, and 1 claim dropped.
- **Final verdict:** the four bounded moves remain on the frontier. Geohot publication is accepted; the DS4CC preservation block is accepted; the connector survives only at narrow scope; reviewer resolution is accepted.

## Reclamation total and cap

Round 1 reclaimed **141,819,450,393 bytes** and Round 2 reclaimed **8,004,200,659 bytes**, for a total Round-1-plus-2 recovery of **149,823,651,052 bytes**. Rounds 3 and 4 improved narrow runtime hygiene and audit closure rather than claiming additional reclaimed bytes. The home-clean cap is reached.

## Explicit defers

- **DS4CC:** do not reset, reinstall, refresh, clean, or overwrite the managed marketplace. Preserve its unique dirty edits and mutated cache artifacts, then reconcile them deliberately against canonical Work `e52695a` in a separately authorized task.
- **`grok-build`:** defer rebase, formatting/test repair, and publication.
- **`hyperplan-pcbuild/PLAN.md`:** defer pending audience and ownership review.
- **`hutter-prize`:** defer authored and ambiguous files; prior authorization covered classified runtime material only.
- **`ufo-cli`:** defer cross-project upstream correction and any push pending explicit target and ownership review.
- **Downloads, models, credential-bearing or credential-adjacent material:** defer movement, deletion, staging, and publication.
- **Residual dirty repositories and broad `.xbreed` paths:** defer; aggregate status is not path-level authorization.

## Epistemic bound

- **One claim:** Mirror parity at Geohot does not make the dirty managed DS4CC marketplace disposable, because the two conclusions arise from different repository-specific evidence boundaries.
- **Rejected alternative:** Reject resetting or reinstalling DS4CC to force parity; it would overwrite unique managed edits and mutated cache state despite canonical Work already being preserved at `e52695a`.
