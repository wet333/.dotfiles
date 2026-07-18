---
name: openscad-designer
description: Design complex parametric 3D figures in OpenSCAD (.scad) — lofts, sweeps, helices, fillets, fractals, math surfaces, mechanical parts — using a strategy-first workflow plus verified polyhedron/skin generators. Use this skill whenever the user mentions OpenSCAD, SCAD, .scad files, CSG/solid modelling by code, "programmers CAD", parametric models, 3D-printable STL parts, or asks to model/design any physical object, enclosure, bracket, vase, gear, thread, knob, or organic shape in code — even if they never say the word "OpenSCAD" but the deliverable is clearly a scripted 3D model. Also use it to debug, refactor, or parameterize existing .scad code, or when a render is non-manifold, hollow, inside-out, or too slow.
---

# OpenSCAD Designer

OpenSCAD is a functional, declarative CSG language. Complex figures come from picking the
right *construction strategy* first and writing very little code — not from piling up
primitives. A model built with the wrong strategy is usually unfixable and has to be redone,
so spend the thinking budget on step 2 below.

## Workflow

### 1. Pin down the design

Establish before writing code: overall dimensions and units (OpenSCAD is unitless by
convention 1 unit = 1 mm), which dimensions must be parameters, whether it will be
3D-printed (then: manifold, no overhangs > 45°, clearances ~0.2–0.4 mm on mating parts,
minimum wall ≥ 2 perimeters), and whether the output is a preview or an STL.

Ask only what actually blocks the design. If the user gives a loose brief ("a vase", "a
phone stand"), pick sensible defaults, state them in the parameter block, and build — an
argued-for concrete model is more useful than an interview.

### 2. Choose the construction strategy

This is the important decision. Match the figure to a strategy:

| The figure is… | Build it with |
| --- | --- |
| Constant cross-section (extruded profile, plate, bracket) | 2D `polygon`/`offset` + `linear_extrude` |
| Rotationally symmetric (vase, torus, knob, pulley, bowl) | 2D profile + `rotate_extrude` |
| A rounded box, rounded plate, or slot | `offset(r=…)` on the 2D profile, then `linear_extrude` |
| A rounded/organic blob defined by key points | `hull()` over spheres/cylinders at those points |
| Fillet on inside corners / round on outside corners | `offset(r=-r) offset(delta=+r)` / `offset(r=+r) offset(delta=-r)` |
| Cross-section that **changes** along a path (loft, horn, duct, knot, boat hull, tube on a curve) | build rings with list comprehensions → `skin()` (see `references/patterns.md`) |
| Helix, screw thread, twisted column, spring | `linear_extrude(twist=…, slices=…)`, or helical rings → `skin()` |
| Repeated features (holes, fins, teeth, ribs) | `for` + a module; grid or polar array |
| Self-similar / fractal (sponge, tree, Koch) | recursive module with a depth guard |
| A math surface `z = f(x,y)` | point grid → `polyhedron` (or `surface(file=…)` for DAT/PNG data) |
| Text, logos, engraved labels | `text()` + `linear_extrude`; `difference()` to engrave, `union()` to emboss |
| Anything genuinely hard (real fillets between solids, NURBS, gears, threads, attachments) | reach for **BOSL2** — see "Libraries" below |

Two or more strategies usually combine: a body from `rotate_extrude`, features from a polar
`for`, a rounded lip from `offset`. Decompose the figure into named parts and give each part
its own module.

### 3. Write the script in this house structure

Always lay files out in this order. It keeps models readable, Customizer-compatible, and
easy to re-parameterize later.

```openscad
// ============ NAME — one-line description ============
// Units: mm.  Render: F5 preview, F6 render, then Export STL.

/* [Body] */
// Outer diameter of the body
body_d   = 40;    // [10:1:120]
// Wall thickness
wall     = 2.4;   // [0.8:0.4:6]

/* [Features] */
// Number of ribs around the body
rib_count = 6;    // [0:24]
mode = "assembled"; // [assembled, print_plate, section]

/* [Quality] */
$fa = $preview ? 6 : 1;    // fast preview, smooth final render
$fs = $preview ? 0.5 : 0.2;

/* [Hidden] */
eps = 0.01;                // overlap epsilon for booleans

// ---- functions (pure math, no geometry) ----
function rib_angle(i) = 360 * i / rib_count;

// ---- modules (geometry, one job each) ----
module body() { … }
module rib()  { … }

module assembly() {
    difference() {
        body();
        for (i = [0 : rib_count - 1]) rotate([0, 0, rib_angle(i)]) rib();
    }
}

// ---- single top-level call ----
assembly();
```

Conventions that matter:

- **Customizer syntax is load-bearing.** `/* [Section] */` starts a group, a `//` comment on
  the line *above* a parameter becomes its label, and a trailing `// [min:step:max]` or
  `// [a, b, c]` makes a slider or dropdown. Everything under `/* [Hidden] */` is excluded.
  This costs nothing and gives the user a GUI for free.
- **One top-level call.** Everything else is a module. This makes the file `use`-able as a
  library and makes `!`/`*` debugging trivial.
- **Parameterize the intent, not the arithmetic.** Expose `wall`, derive `inner_d = body_d - 2*wall`.
- **Name the magic numbers.** A bare `translate([0, 0, 3.7])` is a bug waiting to happen.

### 4. Validate before delivering

Never hand over a script that has not been checked. In order of preference:

1. **Render it** if the `openscad` CLI is available — this is the only real test:
   ```bash
   openscad -o /tmp/out.stl --hardwarnings model.scad   # non-zero exit = broken model
   openscad -o /tmp/out.png --camera=0,0,0,55,0,25,140 --imgsize=800,600 model.scad
   ```
   `--hardwarnings` turns warnings into failures, which catches the non-manifold and
   `rotate_extrude` mistakes that otherwise ship silently.
2. **Static check** with `scripts/scad_check.py model.scad` when OpenSCAD is not installed.
   It catches unbalanced delimiters, deprecated constructs, missing epsilons in `difference`,
   and other common breakages. It is a lint, not a renderer — it does not prove the model is
   manifold.
3. **Reason through the checklist** in `references/pitfalls.md` regardless. Every item there
   is a failure that looks fine in preview and breaks on F6 or in the slicer.

If a `polyhedron` is generated, verify it before shipping: every directed edge must appear
exactly once and every edge must have an opposite twin. Writing a throwaway script to check
this is far cheaper than debugging a CGAL error.

### 5. Deliver

Save the `.scad` file, tell the user which parameters to turn, and note the render settings
(F5 vs F6, expected render time if it is slow). If a figure is expensive, say so and offer
the cheap variant.

## Rules that keep a model valid

These four cause most broken models. `references/pitfalls.md` has the rest with fixes.

- **Overlap everything you union; overshoot everything you subtract.** Coincident faces are
  undefined behaviour. Cutting a hole through a 10-thick plate uses `cylinder(h = 10 + 2*eps)`
  translated by `-eps`, not `h = 10`.
- **`difference()` subtracts children 2…n from child 1.** Order is meaning. Wrap the base in
  `union(){}` if it is several objects.
- **Holes come out undersized.** `$fn` polygons are inscribed in the circle. For a fitting
  hole use `r / cos(180 / $fn)`, or set `$fn` high enough that the error is under the
  printer's tolerance.
- **Variables are compile-time constants.** The *last* assignment in a scope wins everywhere
  in that scope. `x = x + 1;` is not a thing. Use `let()`, recursion, or list comprehensions.

## Resolution: `$fa`, `$fs`, `$fn`

`$fn` (default 0) fixes the fragment count and overrides the others; `$fa` (default 12°) is
the minimum fragment angle and `$fs` (default 2 mm) the minimum fragment length. Prefer
`$fa`/`$fs` globally so small features stay cheap and big ones stay smooth, and reserve `$fn`
for the local cases where an exact facet count is the point (`$fn=6` for a hex nut,
`$fn=3` for a triangle). `$fn` on a `minkowski()` child is quadratic — a pair of `$fn=100`
cylinders is 10 000 operations, not 200.

Gate quality on `$preview` so F5 stays interactive and F6 comes out smooth.

## Libraries

Vanilla OpenSCAD has no fillets between solids, no sweeps, no gears, no threads. When a
figure needs them, **BOSL2** (BSD-2, `include <BOSL2/std.scad>`) is the standard answer:
`cuboid(rounding=…)`, `path_sweep()`, `skin()`, `vnf_vertex_array()`, `offset_sweep()`,
`prism_connector()` for filleted joints, `attach()` for positioning parts relative to each
other, plus beziers, NURBS, metaballs and texturing.

Say up front whether a script needs a library. If the user cannot install one, build it from
the patterns in `references/patterns.md` instead — they are dependency-free.

## Reference files

Read the one that matches the task; do not load all three by reflex.

- **`references/patterns.md`** — copy-adaptable recipes: rounded box, fillets, `skin()` loft,
  sweep along a 3D path, helix/thread, polar & grid arrays, recursive fractals, solid
  heightfield, text engraving, shells, print-plate layout. The `skin()`, sweep and heightfield
  generators here are numerically verified as watertight and correctly wound — use them rather
  than improvising a `polyhedron`.
- **`references/language.md`** — condensed language reference: every primitive, transform,
  boolean, extrusion, list comprehension, module/function/recursion form, special variable and
  modifier, with the version each feature requires. Read when unsure of exact syntax or
  semantics.
- **`references/pitfalls.md`** — the failure catalogue: non-manifold unions, inside-out
  polyhedra, `rotate_extrude` crossing the Y axis, minkowski blowups, undersized holes,
  compile-time variables, 2D/3D mixing, slow renders. Read when something is broken or slow,
  and skim before delivering.

## Debugging

Modifier characters are the fastest tool in the language: `!` renders only that subtree,
`*` disables it, `#` highlights it in transparent red (perfect for seeing what a
`difference()` is actually removing), `%` shows it as a transparent, non-geometric ghost.
`echo()` prints values; `assert(cond, "msg")` fails the render loudly and belongs on every
parameter that has a valid range. For a suspect `polyhedron`, View → Thrown Together (F12)
paints reversed faces pink.
