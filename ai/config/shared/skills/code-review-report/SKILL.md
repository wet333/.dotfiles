---
name: code-review-report
description: Use this skill when producing or assembling a code-review report — the structured output every code-review agent in this suite emits and the orchestrator aggregates. Defines verdicts, severities, finding shape, style guide, and the output skeleton. Load it before writing any review findings.
---

# Code Review Report

This is the schema every code-review agent in this suite uses. Loading this skill is mandatory before emitting any findings; consistency is what lets the orchestrator aggregate the three specialists into one coherent report.

## Verdicts

Two levels — per dimension and overall:

| Verdict | Meaning |
|---|---|
| `approve` | No blockers, only warnings/nits or nothing at all. Safe to merge. |
| `request-changes` | At least one blocker. Must be addressed before merge. |
| `needs-discussion` | No blocker, but trade-offs, disagreements, or architecture concerns the team should weigh in on. |

The orchestrator computes the overall verdict from the per-dimension ones:

- Any dimension is `request-changes` → overall `request-changes`.
- All dimensions are `approve` → overall `approve`.
- Otherwise → `needs-discussion`.

## Severities

Each finding is tagged exactly one of:

| Severity | Meaning |
|---|---|
| `blocker` | Must fix before merge. Bugs, security holes, data loss, broken contracts, missing tests for new behavior. |
| `warning` | Should fix. Performance smells, error-handling gaps, maintainability issues, missing docs on public API. |
| `nit` | Optional. Style, naming, small refactors, subjective preferences. |

## Finding shape

Every finding is one bullet with this exact shape:

```
- **<short imperative title>** — `<relative/path/to/file.ext>:<line>`
  - **Issue:** <one sentence: what's wrong>
  - **Suggestion:** <concrete fix, code snippet when useful>
  - **Rationale:** <one sentence: why this matters>
```

- `<relative/path/to/file.ext>` is relative to the repo root.
- `<line>` is the most relevant line; use a range (`40-52`) if the issue spans lines, or omit if file-wide.
- `Issue`, `Suggestion`, `Rationale` are each one sentence, terse, no filler.

## Style guide

- One finding per bullet. No nested findings.
- Every blocker and warning MUST include a `Suggestion` and a `Rationale`. Nits may omit `Rationale`.
- Order findings inside each dimension: `blocker` → `warning` → `nit`. Within a severity, sort by file path then line number.
- Cite a location for every finding. A finding without a file:line is not actionable and will be discarded.
- No vague hand-waving. "Consider refactoring" / "improve readability" / "this could be better" are not findings.
- Don't restate the code. The reader can read.
- When a finding is genuinely a tradeoff, mark the dimension verdict `needs-discussion` and frame the finding as a question, not a directive.

## Output skeleton (orchestrator)

The orchestrator stitches specialist output into this skeleton:

```markdown
# Code Review: <target>

## Summary
<one paragraph: what was reviewed, scope if narrowed, overall verdict, top 1-2 concerns>

## Findings

### Safety
**Verdict:** approve | request-changes | needs-discussion

#### Blockers
- **<title>** — `<path>:<line>`
  - **Issue:** ...
  - **Suggestion:** ...
  - **Rationale:** ...

#### Warnings
- (same shape)

#### Nits
- (same shape)

### Quality
**Verdict:** ...

### Design
**Verdict:** ...

## Overall Verdict
**approve** | **request-changes** | **needs-discussion**

<one-line next action>
```

Each specialist emits ONLY its own `### <Dimension>` block (including the `**Verdict:**` line and its severity sub-sections). The orchestrator fills the summary, the section ordering, and the overall verdict.

## Self-check before emitting

Before returning a report, run through this:

- Every finding has a file:line.
- Every blocker/warning has a Suggestion (and a Rationale; nits may skip Rationale).
- Per-dimension verdict matches the severities present.
- No invented APIs, line numbers, or file contents — if unsure, re-read the file.
