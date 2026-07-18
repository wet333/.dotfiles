# Pitfalls: what breaks, why, and the fix

Almost everything here **looks correct in F5 preview** and fails at F6, at export, or in the
slicer. Skim the checklist before delivering any model.

## Pre-delivery checklist

- [ ] Every union has overlapping (not coincident) faces.
- [ ] Every subtracted tool overshoots the material it cuts, at both ends.
- [ ] `difference()`'s first child is the whole base (wrapped in `union(){}` if it is several).
- [ ] Fitting holes are compensated for polygon inscription, or `$fn` is high enough.
- [ ] `rotate_extrude` children lie entirely at `x >= 0`.
- [ ] Any hand-written `polyhedron` is closed, non-overlapping, and wound clockwise-from-outside.
- [ ] No 2D and 3D children mixed inside one boolean.
- [ ] `$fn` is not large on a `minkowski()` child.
- [ ] Assertions guard every parameter with a real valid range.
- [ ] F6 completes and the part does not vanish. (`openscad -o out.stl --hardwarnings` exits 0.)

---

## Coincident faces → non-manifold

**Symptom:** flickering preview artifacts; F6 warns; parts of the model disappear from the
STL; the slicer reports a non-manifold mesh.

**Cause:** unioning or differencing objects whose external faces are exactly coplanar. Two
`rotate([17,0,0])` calls do not produce bit-identical vertices — irrational rotations cannot
be represented exactly, so "exactly touching" is undefined behaviour. This is intrinsic to
floating point, not a bug to wait out.

**Fix:** an epsilon, in *both* directions.

```openscad
eps = 0.01;
// union: overlap
union() { cube([10,10,10]); translate([0,0,10-eps]) cube([4,4,5]); }
// difference: overshoot both ends of the cut
difference() { cube([10,10,10]); translate([5,5,-eps]) cylinder(h = 10 + 2*eps, r = 2); }
```

## Holes come out undersized

**Symptom:** the M3 screw does not fit the `r=1.5` hole.

**Cause:** `$fn` approximates a circle with an **inscribed** polygon — its flats lie inside
the true circle, so the hole is smaller than nominal everywhere except at the vertices.

**Fix:** circumscribe, or raise `$fn` until the sagitta is below tolerance.

```openscad
function circumscribed_r(r, n) = r / cos(180 / n);
module hole(r, h, n = 24) { cylinder(h = h, r = circumscribed_r(r, n), $fn = n); }
```

## `rotate_extrude` produces nothing

**Symptom:** console warning, no geometry, or a CGAL error.

**Cause:** the profile crosses the Y axis (some vertices `x > 0`, some `x < 0`), or it
touches `x = 0` at a single point instead of along a line.

**Fix:** keep every vertex at `x >= 0`. If the profile is a shape you translated, remember the
translate happens in the 2D plane *before* projection: `translate([2,0]) circle(1)` is valid,
`translate([0.5,0]) circle(1)` is not.

## The polyhedron is inside-out or leaks

**Symptom:** the solid vanishes when unioned with a cube and rendered; F12 shows pink faces;
CGAL errors.

**Cause:** wrong winding, a missing face, overlapping faces, or a non-manifold edge.

**Fix:** OpenSCAD wants each face listed **clockwise viewed from outside** (right-hand normal
pointing *inward*) — the opposite of the STL/OBJ convention, which is the usual reason
imported logic is backwards. Two rules must hold: exactly two faces meet at every edge, and
faces sharing a vertex form a single cycle around it.

Verify mechanically rather than by eye: every directed edge `(a,b)` must appear exactly once
across all faces, and every `(a,b)` must have a matching `(b,a)`. A short throwaway script
checking this costs a minute and saves an hour. Prefer the verified `skin()` in
`patterns.md` over a hand-rolled `polyhedron`.

To debug interactively: comment out faces to view them individually, and use F12 (Thrown
Together) — reversed faces render pink.

## `x = x + 1` and disappearing values

**Symptom:** `echo` prints a value from later in the file; a loop "counter" never changes.

**Cause:** variables are compile-time constants. The last assignment in a scope applies to the
entire scope. Assignments never leak out of an inner scope.

**Fix:** `let()` for locals, recursion or list comprehensions for accumulation, `for` for
repetition. If a value must vary per iteration, compute it from the loop variable.

```openscad
// wrong                          // right
total = 0;                        function total(v, i = 0) =
for (x = data) total = total + x;     i >= len(v) ? 0 : v[i] + total(v, i + 1);
```

## Minkowski takes forever

**Symptom:** F6 never finishes; RAM climbs.

**Cause:** `minkowski()` combines every node of each child with every node of the other. Two
`$fn=100` cylinders is 100 × 100 = 10 000 operations, not 200. A compound child may also be
treated as separate inputs, producing an oversized result with stray features.

**Fix:** use `offset(r=…)` on a 2D profile then `linear_extrude` (orders of magnitude faster),
or `hull()` of spheres. If Minkowski is genuinely needed: keep `$fn` on the rounding child low
(16–24 is plenty), wrap compound children in `union()`, and remember the result grows by the
second child's extent — shrink the first child to compensate.

## The render is slow

In rough order of payoff:

- Gate resolution on preview: `$fa = $preview ? 6 : 1; $fs = $preview ? 0.5 : 0.2;`
- Drop `$fn` globally; raise it only on the features where it shows.
- Replace `minkowski()` with `offset()`+`linear_extrude` or `hull()`.
- Replace 3D booleans with 2D booleans before extruding — 2D CGAL is far cheaper.
- Reduce recursion depth; the cost is exponential.
- `render()` a heavily-reused subtree once instead of re-CSGing it per instance.
- `resize()` is a CGAL operation even in preview — use `scale()` when the factor is known.
- Isolate the slow part with `!` and time it alone.

## 2D and 3D mixed

**Symptom:** a boolean silently drops children; "mixing 2D and 3D objects is not supported".

**Cause:** a `circle()` inside a `difference()` with a `cube()`, usually after forgetting a
`linear_extrude`.

**Fix:** finish all 2D work (booleans, `offset`), then extrude once. 2D objects render with a
nominal 1-unit thickness for display, which is what makes this look plausible on screen.

## `hull()` ignored my Z translation

`hull()` on 2D children projects them onto XY first and returns a 2D result — Z has no effect.
To hull in 3D, give it 3D children (spheres, cylinders).

## The text is the wrong size, or missing

`text()` needs 2015.03+. A font that is not installed falls back silently to another, changing
every dimension. Use the bundled Liberation faces unless the user names a font, and register
project fonts with `use <font.ttf>`. An engraved cut with zero depth (exactly flush) will not
survive the slicer — cut `depth + eps` and start `eps` below the surface.

## `linear_extrude(scale=[a,b])` looks asymmetric

A vector `scale` makes the side walls non-planar and the triangulation asymmetric. Set
`twist = 0` and an explicit `slices` to control it.

## Colours vanish on export

`color()` is preview-only. F6/CGAL and STL carry no colour. Export 3MF if per-part colour must
survive, or ship the parts as separate STLs.

## 3D-printing specifics

- **Clearance:** mating parts need 0.2–0.4 mm of gap per side; nominal dimensions bind.
- **Overhangs** past ~45° need support. Design the print orientation into the model
  (see the `print_plate` mode in `patterns.md`), do not leave it to the slicer.
- **Walls** should be a multiple of the nozzle width — 1.6 mm (4 × 0.4) is a safe default.
- **First layer:** avoid knife-edge contact; add a small chamfer to bottom edges to fight
  elephant's foot.
- **Holes print undersized** on top of the polygon inscription problem — thermal shrink adds
  ~0.1–0.2 mm. Vertical holes for screws are worth oversizing deliberately.
- **Text** below ~0.6 mm of relief and ~4 mm of size will not resolve on an FDM printer.
