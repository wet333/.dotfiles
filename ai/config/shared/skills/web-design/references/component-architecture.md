# Component Architecture & Code Conventions

Conventions for scalable, easily modifiable frontend code. Default stack: **Next.js (stable, App Router) + React + TypeScript + Tailwind CSS**, all at their current stable/LTS releases. If the project already exists, match its versions and conventions — consistency beats preference.

## Directory layout

```
app/                        # Routes. Pages are THIN: import sections, compose, done.
  layout.tsx                # Root layout: fonts, metadata, <Header/>, <Footer/>
  page.tsx                  # Home = <Hero/> <Features/> <Testimonials/> <CTA/>
  about/page.tsx
  globals.css               # Tailwind directives + CSS variables (tokens)
components/
  ui/                       # Atoms — generic, reusable, subject-agnostic
    Button.tsx
    Card.tsx
    Badge.tsx
  sections/                 # Organisms — one per page section, subject-aware
    Hero.tsx
    Features.tsx
    Footer.tsx
  layout/                   # Structural helpers
    Container.tsx           # max-width + horizontal padding, used by every section
    Header.tsx
lib/
  content.ts                # Copy/data as typed constants — text lives here, not inline
  utils.ts                  # cn() class-merge helper, formatters
DESIGN.md
tailwind.config.ts          # Token definitions (colors, fonts, spacing extensions)
```

**The dependency rule:** `app/` imports from `sections/`, sections import from `ui/` and `layout/`. Never the reverse. Atoms know nothing about the site's content.

## Tokens in Tailwind

Define every design decision once, in the config or as CSS variables:

```ts
// tailwind.config.ts (excerpt)
export default {
  theme: {
    extend: {
      colors: {
        primary: "hsl(var(--primary))",
        accent: "hsl(var(--accent))",
        surface: "hsl(var(--surface))",
        ink: "hsl(var(--ink))",
      },
      fontFamily: {
        display: ["var(--font-display)", "serif"],
        body: ["var(--font-body)", "sans-serif"],
      },
    },
  },
};
```

Then components use `bg-surface text-ink font-display` — never `bg-[#f7f3ee]`. Arbitrary values (`w-[347px]`) are a code smell; if a value matters, it deserves a token.

Load fonts via `next/font` (self-hosted, no layout shift) and expose them as the CSS variables referenced above.

## Component patterns

**Variants via props, not duplication:**

```tsx
// components/ui/Button.tsx
import { cn } from "@/lib/utils";

type ButtonProps = React.ComponentProps<"button"> & {
  variant?: "primary" | "ghost";
  size?: "md" | "lg";
};

export function Button({ variant = "primary", size = "md", className, ...props }: ButtonProps) {
  return (
    <button
      className={cn(
        "inline-flex items-center justify-center rounded-md font-medium transition-colors",
        "focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-accent",
        variant === "primary" && "bg-primary text-surface hover:bg-primary/90",
        variant === "ghost" && "bg-transparent text-ink hover:bg-ink/5",
        size === "md" && "h-11 px-5 text-sm",   // h-11 = 44px: minimum touch target
        size === "lg" && "h-12 px-7 text-base",
        className
      )}
      {...props}
    />
  );
}
```

**Sections take data, don't hardcode it:**

```tsx
// components/sections/Features.tsx
import { features } from "@/lib/content";
import { Container } from "@/components/layout/Container";

export function Features() {
  return (
    <section className="py-16 md:py-24">
      <Container>
        <div className="grid gap-6 sm:grid-cols-2 lg:grid-cols-3">
          {features.map((f) => (
            <article key={f.title} className="rounded-lg bg-surface p-6">
              <h3 className="font-display text-xl">{f.title}</h3>
              <p className="mt-2 text-ink/70">{f.body}</p>
            </article>
          ))}
        </div>
      </Container>
    </section>
  );
}
```

Editing copy or adding a feature card now means touching `lib/content.ts` only. That's the scalability the user is paying for.

**Server components by default.** Add `"use client"` only where interactivity requires it (event handlers, hooks), and push it as far down the tree as possible.

## Responsive rules (mobile-first)

1. **Unprefixed classes = mobile.** Add `sm:` `md:` `lg:` only to change something as the screen grows. If you catch yourself writing `lg:block hidden`... that's fine (mobile hides it), but `block lg:hidden` styled desktop-first thinking should make you pause and re-check the whole component.
2. **Prefer intrinsic responsiveness** over breakpoint stacking:
   - `grid-cols-[repeat(auto-fit,minmax(16rem,1fr))]` instead of manual col counts when items are uniform
   - Fluid type: `text-[clamp(2rem,5vw,3.5rem)]` (or a clamp-based scale in the config)
   - `flex flex-wrap gap-4` for tag rows, nav items
3. **Verify the three viewports** on every page: 375px (no horizontal scroll, touch targets ≥ 44px, nav usable with a thumb), 768px (layout expands sensibly, not just stretched mobile), 1280px+ (content capped with `max-w-*`, line length ≤ ~70ch).
4. **Images:** always `next/image` with proper `sizes`; art-direct with different aspect ratios per breakpoint when the hero demands it.
5. **Navigation:** mobile gets a compact pattern (drawer/sheet with a real `<button aria-expanded>`); desktop gets the horizontal bar. Same component, responsive rendering.

## Quality floor (non-negotiable at every originality level)

- Semantic landmarks: `<header> <nav> <main> <section> <footer>`, one `<h1>` per page, heading levels in order
- `focus-visible` styles on every interactive element (see Button above)
- `alt` on every image; decorative images get `alt=""`
- Motion wrapped in `motion-safe:` variants or a `prefers-reduced-motion` media query
- Color contrast: body text ≥ 4.5:1, large text ≥ 3:1 — check tokens at design time, not after
- Keyboard: the whole page must be operable with Tab/Enter/Escape

## Common CSS pitfalls

- Watch selector/utility conflicts when mixing custom CSS with Tailwind — section padding utilities silently overridden by a global `.section` rule is a classic. Prefer utilities; if custom CSS is unavoidable, scope it narrowly.
- Don't fight Tailwind's cascade with `!important`; restructure instead.
- Vertical rhythm: pick one spacing owner. Either sections own their `py-*` or a parent owns `space-y-*` / `gap-*` — never both, or spacing doubles unpredictably.
