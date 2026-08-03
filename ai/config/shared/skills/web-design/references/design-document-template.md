# DESIGN.md Template

Create this file at the project root the first time you design for a project, and update it on every subsequent design session. Copy the structure below and fill it in with the project's actual values. Keep it concise — it's a working reference, not documentation theater.

```markdown
# Design Document — [Project Name]

> Source of truth for all visual and structural design decisions.
> Read this fully before making any design change. Update it after every change.

## 1. Brief

- **Subject:** [What the site/product is]
- **Audience:** [Who it's for]
- **Primary goal:** [The one action/feeling the site must produce]
- **Voice:** [3 adjectives, e.g., "warm, precise, unhurried"]
- **Originality level:** [1 Standard | 2 Detailed | 3 Creative | 4 Original | 5 Crazy]

## 2. Color tokens

| Token | Hex | Role |
|---|---|---|
| `primary` | #...... | [dominant / brand] |
| `secondary` | #...... | [supporting] |
| `accent` | #...... | [CTAs, highlights — use sparingly] |
| `surface` | #...... | [backgrounds] |
| `ink` | #...... | [body text] |
| `muted` | #...... | [secondary text, borders] |

Contrast notes: [e.g., "ink on surface = 12.3:1 ✓; accent on surface only for text ≥ 18px"]

## 3. Typography

| Role | Family | Weights | Usage |
|---|---|---|---|
| Display | [Font] | [e.g., 700] | Headlines only; tracking [-0.02em] |
| Body | [Font] | [400, 500] | All running text; line-height 1.6 |
| Utility | [Font, optional] | [400] | Captions, labels, data |

Type scale: [e.g., "clamp-based fluid scale: 1rem base, 1.25 ratio; h1 = clamp(2rem, 5vw, 3.5rem)"]

## 4. Spacing & layout

- Spacing scale: [e.g., "Tailwind default; sections use py-16 md:py-24"]
- Container: [e.g., "max-w-6xl mx-auto px-4 sm:px-6"]
- Grid logic: [e.g., "1 col mobile → 2 col md → 3 col lg via auto-fit minmax(280px, 1fr)"]
- Radius / borders / shadows: [the consistent treatment used site-wide]
- Breakpoint philosophy: mobile-first; base = mobile, sm: 640, md: 768, lg: 1024, xl: 1280

## 5. Signature element

**What:** [The one memorable design device]
**Why:** [How it embodies the subject/brief]
**Where it appears:** [Hero only? Recurring motif?]

## 6. Motion

[e.g., "Scroll-reveal on section entry, 400ms ease-out, 12px translate. Hover: scale 1.02 on cards. All wrapped in prefers-reduced-motion guard."]

## 7. Component conventions

- Atoms in `components/ui/`, sections in `components/sections/`, layout in `components/layout/`
- Variants via props (e.g., `<Button variant="primary" | "ghost">`), not duplicated components
- [Any project-specific patterns]

## 8. Copy voice

[e.g., "Sentence case everywhere. Active verbs on buttons ('Book a table', never 'Submit'). No exclamation marks."]

## 9. Decision log

| Date | Decision | Rationale |
|---|---|---|
| YYYY-MM-DD | [Initial design system created] | [Summary of the direction chosen and level] |
| YYYY-MM-DD | [e.g., Swapped accent from X to Y] | [Why] |
```

## Rules for maintaining it

- **Append to the decision log** every session; never silently overwrite a past rationale — supersede it with a new dated entry.
- If the user requests a change that contradicts the document (e.g., a new color), make the change **and** update the token + log entry.
- If a full redesign is requested, archive the old token tables inside a collapsed "Previous direction" section at the bottom rather than deleting them.
- Keep the document under ~150 lines. It should be readable in one pass.
