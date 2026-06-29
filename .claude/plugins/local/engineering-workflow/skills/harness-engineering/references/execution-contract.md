# Execution Contract — Template & Guide

The execution contract is a **single compressed document** that captures the
essential agreement between planning and execution. It is generated from
source artifacts (STATE.md, plan docs, configs) before execution begins,
and serves as the **only handoff** between planner and executor.

## Why a Contract?

- **Prevents scope drift** — executor works against a frozen contract, not a
  moving plan document
- **Enables independent verification** — verifier checks output against
  contract without reading the planner's reasoning
- **Makes staleness detectable** — if source artifacts change, the contract's
  integrity hash mismatches → execution is blocked until re-contract

## Contract Template

```markdown
# Execution Contract: `<task-name>`

## Intent Lock

Derived from: `docs/harness/active/<plan-file>.md`

> One-line objective from the plan document. This is the "why" — if the
> executor cannot achieve this, it must escalate, not improvise.

## Approved Behavior (In Scope)

- Concrete actions the executor IS allowed to take
- File paths, parameters, and tolerances the executor may modify
- Any code generation, data transformation, or analysis permitted

## Design Constraints (Out of Bounds)

- Actions the executor MUST NOT take
- Architectural boundaries that must be preserved
- Files, directories, or services that are read-only

## Task Batches

| Batch | Action | Acceptance Criteria | Depends On |
|-------|--------|-------------------|------------|
| 1     | ...    | ...               | —          |
| 2     | ...    | ...               | Batch 1    |

## Test Obligations

- Every batch must complete its acceptance criteria before the next starts
- Final verification: `bash scripts/check-harness.sh audit`

## Review Gates

| Gate | Trigger | Reviewer | Artifact Required |
|------|---------|----------|-------------------|
| L1   | Per-batch complete | Verifier agent | Output files + brief |
| L3   | All batches done | Human | execution-contract.md + results |

## Source Integrity

| Source File | SHA256 | Last Validated |
|-------------|--------|----------------|
| ...         | ...    | ...            |
```

## When to Generate

1. **After planning, before execution** — plan artifact exists, configs are
   drafted, but no code has been run yet
2. **When resuming a paused loop** — re-validate source integrity hashes
3. **When plan artifact changes** — any edit to `docs/harness/active/` or
   configs invalidates the contract

## When to Reject

The executor MUST NOT proceed if:
- Source integrity hashes don't match (content changed since contract generation)
- A required artifact is missing or unreadable
- The intent lock is ambiguous (cannot be verified by a script)
- Any batch has empty acceptance criteria
