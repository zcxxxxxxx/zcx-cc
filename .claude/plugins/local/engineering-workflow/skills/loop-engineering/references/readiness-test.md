# Readiness Test & Loop Triggers

## The 4-Condition Readiness Test

Not every task belongs in a loop. Before building one, verify all four:

| # | Condition | Why it matters | If it fails |
|---|-----------|----------------|-------------|
| 1 | **Task repeats** — does this happen more than once? | One-off tasks don't need a loop | Don't build a loop. Write a script. |
| 2 | **Auto-verification exists** — can a machine tell success from failure? | Without this, the loop can't self-correct | Add tests/metrics first, then loop. |
| 3 | **Token budget fits** — can it run 10x without surprise? | Loops amplify cost on failure | Cap cost per cycle before enabling. |
| 4 | **Agent has tools** — APIs, runtimes, permissions? | Permission walls every cycle = broken loop | Pre-configure access. Test manually first. |

## When to Loop

| Appropriate for loops | NOT appropriate for loops |
|----------------------|---------------------------|
| Lint fixes, dependency updates | Architecture rewrites, auth logic |
| CI-failure classification | Payment code, security policy |
| Parameter sweeps, batch validation | Product decisions, API design |

## Loop Triggers (Platform-Agnostic)

| Trigger type | When to use | Claude Code | Other platforms |
|-------------|-------------|-------------|-----------------|
| **Timer** | Fixed-interval tasks (nightly batch, hourly check) | `/loop 30m: <task>` | cron, ScheduleWakeup |
| **Goal-driven** | Run until condition met (sweep, optimization) | `/goal: <condition>` | Custom orchestrator |
| **Event** | Triggered by external event (git push, webhook) | `/schedule` + hook | GitHub Actions, CI webhook |
| **Scheduled** | Specific time, runs offline | `/schedule "<cron>" <task>` | cron, Airflow, Dagster |
