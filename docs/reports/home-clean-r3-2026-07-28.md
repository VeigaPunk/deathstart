# Home cleanup — Round 3 audit report

- **Round:** `home-clean-r3`
- **Date:** 2026-07-28
- **Scope:** narrow runtime-ignore publication and a 22-root residual-state audit under `/home/vhpnk`
- **Publication state:** report-only working-tree addition; this task did not stage, commit, or push

## Round-3 axes

1. Publish only the exact xbreed mailbox runtime-log ignore needed by each selected repository.
2. Prove that adjacent `.xbreed` content remains visible rather than broadening the ignore boundary.
3. Verify commit, upstream, worktree, and diff-check state after publication.
4. Re-audit all 22 repository roots and separate clean roots, dirty roots, and upstream divergence.
5. Reconcile cross-repository scope without turning aggregate evidence into repository-specific assertions.
6. Produce a spoof-resistant evidence audit, Pareto disposition, and bounded Round-4 handoff.

## ROUND_ROSTER

| Axis | Sublead lane |
|---|---|
| Phase-0 inventory and additional axes | `the-planner-home-clean-r3` |
| Narrow ignore implementation/publication | `ccs-executor-runtime-ignore-r3` |
| Publication and residual-state review | `cdx-reviewer-home-clean-r3` |
| Cross-root coherence and scope caution | `cdx-connector-home-clean-r3` |
| Evidence synthesis and source-map reveal | `cdx-distiller-home-clean-r3` |
| Round report | `cdx-scribe-home-clean-r3` |

## xask lanes

| Lane | Target | Purpose |
|---|---|---|
| Implementation/publication | `--spark --gs codex` | Add the path-anchored runtime ignore, run narrow checks, commit only `.gitignore`, and non-force push. |
| Review/residual audit | `--gpt55 --gs -e low codex` | Verify both publications and classify the 22 Git roots without mutating residual debt. |
| Cross-root coherence | `--spark --gs codex` | Compare publication state, dirty-state totals, and upstream exceptions while preserving source scope. |
| Synthesis | `--gpt55 --gs -e low codex` | Reconcile three moves, reveal provenance, recompute the audit hash, and issue the Pareto verdict. |

Every delegated prompt inherited Godspeed and ended with `| godspeed` or, for executor prompts, `| godspeed-impl`.

## R3 move execution record

| Move | Durable result | Verification evidence | Verdict |
|---|---|---|---|
| `R3-M01` | `deathstart` commit `dc9260c` (`dc9260cc82ca07577d3e6f8f624709682e5f118f`) pushed to `origin/main`. | The commit changes only `.gitignore`; `git diff --check dc9260c^ dc9260c` passed, the target path matched the ignore rule, an adjacent sentinel path did not match, `HEAD...origin/main` was `0 0`, and the post-drain worktree was clean before this report was added. | **KEEP.** |
| `R3-M02` | `the-musketeer` commit `7a4ec99` (`7a4ec999abe8c810f272c0f894ce6fc9618af798`) pushed to `origin/main`. | The commit changes only `.gitignore`; `git diff --check 7a4ec99^ 7a4ec99` passed, the target path matched the ignore rule, an adjacent sentinel path did not match, `HEAD...origin/main` was `0 0`, and the worktree was clean. | **KEEP.** |
| `R3-M03` | Completed the 22-root residual audit: **6 dirty**, **1 clean-but-diverged `ufo-cli` root**, and **15 clean**. | The categories total 22 roots. Dirty and divergent roots remained unmodified; the prior `ufo-cli` cross-project upstream exception remains a divergence disposition, not permission to push. | **KEEP.** |

## Exact narrow ignore rule and tests

Both publication commits added the same path-anchored rule:

```gitignore
# xbreed runtime
/.xbreed/mailbox/events.ndjson
```

The leading and trailing path components are intentional: only the repository-root mailbox event log is ignored. Validation used `git check-ignore -v .xbreed/mailbox/events.ndjson` for the positive case and `git check-ignore -v .xbreed/mailbox/keep.txt` for the negative adjacent-path case. Commit-range `git diff --check` passed in both repositories, each branch resolved to `0 0` against `origin/main`, and the full commit hashes above matched the pushed heads.

## Residual audit and connector scope caveat

The 22-root result is an aggregate partition: 6 dirty roots + the separate `ufo-cli` divergence + 15 clean roots. The connector lane compared cross-root coherence and exceptions; it did **not** independently reclassify every dirty path or expand the authorization boundary. Therefore its coherence result must not be read as approval to stage, delete, commit, fix upstreams, or push any residual root.

## Evidence audit and Pareto verdict

EVIDENCE AUDIT: 3 moves with evidence, 0 moves without, 0 dropped, 0 spoof_flagged

- **audit_hash:** `7966479624c14a2afc48c1680379aeb50ac0ff65ce5e37372f82b3c48b99595a`
- **Canonical source-map serialization:** `[{"move_id":"R3-M01","source_prefix":"cdx"},{"move_id":"R3-M02","source_prefix":"cdx"},{"move_id":"R3-M03","source_prefix":"cdx"}]`
- **Hash verification:** the distiller recomputed the SHA-256 over compact UTF-8 JSON sorted by `move_id`, with object keys sorted, comma/colon separators, and no trailing newline; the result matched.
- **R3-M01:** **KEEP.** Narrow runtime hygiene improved without hiding adjacent mailbox content.
- **R3-M02:** **KEEP.** The same bounded improvement was published and verified independently in `the-musketeer`.
- **R3-M03:** **KEEP.** The complete aggregate partition exposes residual debt without mutating or over-authorizing it.

## Round-4 boundary

Round 4 should address **safe runtime debt only**: repository-local, classified, non-authored runtime artifacts with narrow ignore or deletion proof and a reversible verification path. Authored changes, ambiguous files, upstream correction, broad `.xbreed` ignores, and unrelated repository repair remain out of scope.

## Epistemic bound

- **One claim:** The exact event-log rule improves runtime hygiene without concealing adjacent `.xbreed` state, as shown by positive target checks and negative sibling-path checks in both published repositories.
- **Rejected alternative:** Reject a Round-4 sweep over all six dirty roots or the divergent `ufo-cli` root; aggregate residual status is not path-level authorization.
