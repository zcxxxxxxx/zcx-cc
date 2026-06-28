# Loop Engineering Anti-Patterns

## 1. Quality Checks Embedded Inside Pipeline Stages

```
❌ BAD: pipeline stages with embedded quality checks:
     Clean stage: dedup → null fill → quality check
     Load stage
   // The verifier IS the writer — same agent, same context.

✅ GOOD: pipeline + independent verification gate:
     Pipeline: extract → clean → feature-eng → load
     Verify gate (separate agent/script):
       check row counts match, no nulls in key columns,
       schema conforms to target
```

The validator shares the writer's memory and chain-of-thought. It will
overlook errors because it "remembers" what the writer intended.

**Fix:** The verification gate is a separate process/agent that receives
only the output artifacts and has zero knowledge of how they were produced.

## 2. State File Without a Concrete Next Step

```
❌ Next step: continue
   Next step: to be determined

✅ Next step: Run config-3 (mesh_3, k-omega SST, Re=1e6) with relaxation
   factor 0.3. Expected runtime: ~30 min. After completion, run
   check-convergence.sh on the output.
```

If the next step isn't actionable by a fresh agent with no memory, the
state file has failed its purpose.

## 3. Letting the Loop Touch Judgment Calls

Architecture rewrites, authentication logic, payment code, product
decisions — these need human judgment.

| Loop-appropriate | NOT loop-appropriate |
|-----------------|---------------------|
| Lint fixes | Architecture rewrites |
| Dependency updates | Authentication logic |
| CI-failure classification | Payment code |
| Flaky-test reproduction | Product direction changes |
| Parameter sweeps | API design decisions |
| Batch data validation | Security policy changes |

**Test:** If "wrong" is subjective, don't loop it. If the cost of one wrong
answer is high, don't loop it.

## 4. Not Reading the Diff

As loops accelerate, your understanding of the codebase can become shallower.
This is "understanding debt" — one day you'll debug a system no one has read.

> Read the diff before merging loop output, even if you just scan it.
> The cost of a quick review is always less than the cost of debugging an
> autonomous system's mistake weeks later.
