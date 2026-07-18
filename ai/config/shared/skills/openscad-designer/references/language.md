# OpenSCAD language reference (condensed)

Distilled from the official manual and cheat sheet (language v2021.01). Version tags mark
features that fail silently or loudly on older builds — state the requirement when a script
depends on one.

**Contents**
1. [Model of the language](#1-model-of-the-language)
2. [Values, variables, scope](#2-values-variables-scope)
3. [3D primitives](#3-3d-primitives)
4. [2D primitives and text](#4-2d-primitives-and-text)
5. [Extrusion and projection](#5-extrusion-and-projection)
6. [Transformations](#6-transformations)
7. [Booleans](#7-booleans)
8. [Flow control and list comprehensions](#8-flow-control-and-list-comprehensions)
9. [Functions and modules](#9-functions-and-modules)
10. [Special variables](#10-special-variables)
11. [Math, string and utility functions](#11-math-string-and-utility-functions)
12. [Debugging, assert, include/use, import/export](#12-debugging-assert-includeuse-importexport)

---

## 1. Model of the language

A script is a free-form list of statements. **Objects** (primitives) end in `;`. **Actions**
(assignments) end in `;`. **Operators** (transforms, booleans) take no semicolon and apply to
the child that follows, or to a `{ … }` group.

```openscad
operator() action();
operator() { action(); action(); }
operator() operator() action();
```

Chained operators apply **right to left** — the one nearest the object goes first.
`rotate(a) translate(v) cube(5)` translates, then rotates the translated result (an arc);
`translate(v) rotate(a) cube(5)` rotates in place, then moves.

Comments are C++ style: `//` and `/* … */`.

## 2. Values, variables, scope

Types: number (one 64-bit IEEE float — no separate integer type), boolean, string, range,
vector/list, `undef`. There are no type names and no user-defined types. Functions and
variables live in disjoint namespaces.

**Falsy:** `false`, `0`, `-0`, `""`, `[]`, `undef`. Everything else is truthy — including
`"false"`, `[0]`, `[false]`, and `nan`.

`undef` propagates: any arithmetic containing it yields `undef`. `nan` (from `0/0`) is the
only value not equal to itself — test with `x != x`, not `x == 0/0`.

**Variables are compile-time constants.** Within a scope, the last assignment wins
*everywhere* in that scope, including lines above it:

```openscad
a = 0; echo(a);  // prints 5
a = 5;
```

Since 2015.03 assignments are allowed in any scope, but they never leak outward. `x = x + 1;`
is meaningless. Iterate with `for`, accumulate with recursion or list comprehensions, and
bind locals with `let()`.

Ranges are `[start:end]` or `[start:step:end]` — colons, not commas; they are not vectors.
Avoid step values not exactly representable in binary (`0.2` bad, `0.25` fine) or the element
count drifts.

Vectors: `v[2]` indexes from 0; `v.x`, `v.y`, `v.z` alias `v[0..2]`. `len(v)` gives the
length at that nesting level (`undef` for a non-vector); `concat(a, b, …)` joins without
adding nesting (2015.03+). A matrix is a vector of vectors.

## 3. 3D primitives

```openscad
cube(size = [x,y,z] | s, center = false);   // default: corner at origin, first octant
sphere(r = 1 | d =);                        // centred on the origin
cylinder(h = 1, r = | r1 =, r2 = | d =, d1 =, d2 =, center = false);
polyhedron(points = [[x,y,z], …], faces = [[i,j,k, …], …], convexity = 1);
```

`d`, `d1`, `d2` require 2014.03 and must be named. `cylinder` with `center=true` spans
`-h/2 … +h/2`. `cylinder(h, r, 0)` is a cone; `$fn=4` makes a pyramid, `$fn=3` a wedge.

`polyhedron` `faces` (2014.03+; the old `triangles` is deprecated) must **enclose the solid
with no overlap**, and every face's points must be listed **clockwise when viewed from
outside** — equivalently, the right-hand-rule normal points *inward*. Two faces meet at every
edge; faces sharing a vertex form one cycle around it. Non-planar faces are auto-triangulated.
Repeated coordinates in `points` are merged into one vertex. `convexity=10` is a safe default
for preview.

To prove a polyhedron valid: union it with any cube and press F6. If it vanishes, it is not
manifold. F12 (Thrown Together) paints reversed faces pink.

## 4. 2D primitives and text

```openscad
square(size = [x,y] | s, center = false);
circle(r = | d =);                                  // $fn sides = regular polygon
polygon(points = [[x,y], …], paths = [[…], …], convexity = 1);
text(t, size = 10, font = , halign = "left", valign = "baseline",
     spacing = 1, direction = "ltr", language = "en", script = "latin");   // 2015.03+
```

`polygon` is the most capable 2D primitive. With no `paths`, points are used in order. With
several `paths`, the first is the outline and the rest are subtracted — that is how you get
holes in one primitive. `paths` index into `points`; the shape closes automatically.

`circle(r, $fn = n)` is the idiomatic regular n-gon. An ellipse is `resize([a,b]) circle(d=…)`
or `scale([sx,sy]) circle(…)`.

`text()` renders with installed fonts via fontconfig; specify style as
`font = "Liberation Sans:style=Bold Italic"`. The bundled Liberation faces are the portable
choice. Register a project font file with `use <path/font.ttf>`. Escapes: `\u03a9`, `\x41`,
`\U01F600`.

## 5. Extrusion and projection

```openscad
linear_extrude(height, center = false, convexity = 10, twist = 0, slices = , scale = 1) { … }
rotate_extrude(angle = 360, convexity = 2) { … }      // angle: 2019.05+
projection(cut = false) { … }
offset(r = | delta = , chamfer = false) { … }          // 2D only, 2015.03+
```

Both extrusions operate on the **XY projection** of their child. Transforms applied to the 2D
shape before extruding change that projection — so keep 2D children on the XY plane.

`linear_extrude`: `twist` in degrees follows the **left** hand rule; `slices` sets the
intermediate step count and defaults from `$fn` — set it explicitly for smooth twists.
`scale` may be a scalar or a vector; a vector scale makes non-planar side walls, so pair it
with `twist=0` and an explicit `slices`.

`rotate_extrude`: every vertex of the child must satisfy `x >= 0` (recommended) or every one
`x <= 0`. Crossing the Y axis prints a console warning and the extrusion is **ignored**.
Touching the axis is only legal along a line — a single touching point gives a zero-thickness
solid and a CGAL error. Translating the child in X grows the diameter; in Y shifts the result
in Z; in Z does nothing. It cannot make a helix.

`offset`: `r` is radial (rounded corners), `delta` is a parallel offset (sharp corners, or
`chamfer=true` for cut corners). Negative shrinks. Compose for fillet/round:
`offset(r=-3) offset(delta=+3)` fillets concave corners (holes under `2r` vanish);
`offset(r=+3) offset(delta=-3)` rounds convex corners (walls under `2r` vanish).

## 6. Transformations

```openscad
translate([x,y,z])          rotate([ax,ay,az])      rotate(a, v = [x,y,z])
scale([x,y,z])              resize([x,y,z], auto = false, convexity =)
mirror([x,y,z])             multmatrix(m)
color("name", alpha) | color([r,g,b,a]) | color("#rrggbbaa")
offset(r | delta, chamfer)  hull()                  minkowski(convexity)
```

`rotate([ax,ay,az])` applies X, then Y, then Z, each by the right-hand rule. `rotate(a, v)`
turns `a` degrees about the arbitrary axis `v`. A single scalar `rotate(45)` spins about Z —
the 2D case. To aim a cylinder at a point:

```openscad
L = norm(p);  rotate([0, acos(p.z / L), atan2(p.y, p.x)]) cylinder(h = L, r = 1);
```

`mirror(v)` reflects through the plane whose normal is `v`, passing through the origin — it
*moves* the object, it does not copy it. `scale` with a negative factor also mirrors.

`resize` is a CGAL operation on real geometry (slow, even in preview), unlike the OpenGL
transforms. `auto=true` scales 0-dimensions to match.

`multmatrix(m)` takes a 4×3 or 4×4 affine matrix; the fourth row is forced to `[0,0,0,1]`.
Layout: the 3×3 block is scale on the diagonal and shear off it, the fourth column is
translation. It is the only way to **shear**:

```openscad
multmatrix([[1,0,0,0], [0,1,0.7,0], [0,0,1,0]]) cube(10);   // skew Y as Z grows
```

`color()` is preview-only — F6/STL carry no colour (3MF can). Components are 0…1, not 0…255.
Named colours are the W3C/SVG set, case-insensitive. `color(undef)` keeps the default.

`hull()` = convex hull of all children; on 2D children it uses their XY projections and
returns 2D. `minkowski()` = Minkowski sum; the **origin** of the second child is the
addition point, so an uncentred second child gives an asymmetric result, and the outer size
grows by the second child's extent. Cost is the product of the children's facet counts.

## 7. Booleans

```openscad
union() { … }          // implicit when omitted; required to group a difference's base
difference() { … }     // child 1 minus children 2…n
intersection() { … }
render(convexity = 1) { … }   // force a CGAL render of a subtree in preview
```

Never mix 2D and 3D children in one boolean.

External faces that are merged must **not be coincident** — that is undefined behaviour and
yields non-manifold renders, flickering previews, and dropped geometry. This is intrinsic to
floating point, not a bug. Always overlap by a small epsilon:

```openscad
eps = 0.01;
union() {
    cube([10, 10, 10]);
    translate([0, 0, 10 - eps]) cube([4, 4, 5]);
}
```

## 8. Flow control and list comprehensions

```openscad
for (i = [0:5]) …                 for (i = [0:2:10]) …          for (i = [a, b, c]) …
for (i = …, j = …) …              // nested, j varies fastest
intersection_for (i = …) …        // intersects the results instead of unioning
if (cond) … else if (cond) … else …
let (a = 1, b = a + 1) …
```

`for` bodies each get their own scope, so a loop variable can differ per pass — but this is
still not mutation.

List comprehensions build data (2015.03+; `each` and C-style `for` 2019.05+):

```openscad
[ for (i = [0:9]) i * i ]                          // generate
[ for (i = [0:9]) if (i % 2 == 0) i ]              // filter
[ for (i = [0:9]) if (i % 2) i else -i ]           // branch
[ for (i = [0:9]) let (s = sin(36 * i)) [i, s] ]   // bind
[ for (v = nested) each v ]                        // flatten one level
[ for (a = [0:2], b = [0:2]) [a, b] ]              // nested -> flat list of 9
[ for (i = 0; i < 10; i = i + 1) i ]               // C-style
```

These are the backbone of complex geometry: generate the point list, then hand it to
`polygon` or `polyhedron` in one call.

## 9. Functions and modules

```openscad
function name(a, b = 2) = expression;      // returns a value; no geometry
module  name(a, b = 2) { … }               // emits geometry; no return value
f = function (x) x * x;                    // function literal, 2021.01+
```

Functions are pure expressions — recursion plus `?:` replaces loops:

```openscad
function sum(v, i = 0) = i >= len(v) ? 0 : v[i] + sum(v, i + 1);
function fact(n) = n <= 1 ? 1 : n * fact(n - 1);
```

**Operator modules** take children and are what makes a model composable:

```openscad
module ring(n, r) { for (i = [0:n-1]) rotate([0, 0, 360*i/n]) translate([r,0,0]) children(); }
ring(6, 20) cylinder(h = 4, r = 2);
```

`children()` emits all children, `children(i)` the i-th, `children([a:b])` a range;
`$children` is the count. Recursive modules need an explicit base case — there is no depth
limit protecting you.

Arguments are positional or named; once one is named, the rest must be. Built-in modules and
functions can be overridden by defining your own with the same name.

## 10. Special variables

`$`-prefixed variables are dynamically scoped: set them on a parent and every descendant sees
the value. That is why `cylinder(…, $fn = 8)` works as an argument.

| Variable | Meaning |
| --- | --- |
| `$fn` | fixed fragment count per 360°; **overrides** `$fa`/`$fs` when ≥ 3. Default 0 |
| `$fa` | minimum fragment angle, degrees. Default 12 |
| `$fs` | minimum fragment length, mm. Default 2 |
| `$t` | animation step, 0…1 |
| `$preview` | `true` under F5, `false` under F6 — gate quality and expensive branches on it |
| `$children` | number of children passed to the current module |
| `$vpr`, `$vpt`, `$vpd`, `$vpf` | viewport rotation / translation / camera distance / FOV |

Fragment count is `$fn ? max($fn,3) : ceil(max(min(360/$fa, r*2*PI/$fs), 5))`. Prefer
`$fa`/`$fs` globally so resolution tracks feature size; use `$fn` locally where an exact
facet count is the design (hex, triangle, square).

## 11. Math, string and utility functions

Trig is in **degrees**: `sin cos tan asin acos atan atan2(y,x)`.

Other math: `abs sign floor ceil round sqrt pow exp ln log min max norm cross rands lookup`.
`min`/`max` take scalars or a vector. `norm(v)` is the Euclidean length; `cross(a,b)` is the
3D cross product. `rands(min, max, count, seed)` returns a vector.

Vector arithmetic: `v1 + v2`, `v * scalar`, `v1 * v2` (dot product), matrix `*` matrix and
matrix `*` vector all work as expected.

Strings: `str(a, b, …)` concatenates anything into a string; `chr(n)`, `ord(c)`;
`len(s)` counts characters; `s[i]` indexes. `search(match, list, num_returns, index_col)`
looks values up in a list/table.

`concat`, `lookup(key, table)` (linear-interpolating table lookup), `version()`,
`version_num()`, `parent_module(i)`.

Type tests (2015.03+): `is_undef is_bool is_num is_string is_list is_function`.

## 12. Debugging, assert, include/use, import/export

**Modifier characters** — put one before any statement:

| Char | Effect |
| --- | --- |
| `*` | disable this subtree |
| `!` | render **only** this subtree (isolate a part instantly) |
| `#` | highlight in transparent red — shows what a `difference()` actually removes |
| `%` | background: transparent ghost, excluded from the geometry |

`echo(…)` prints to the console; the echo **function** form `echo(x) expr` (2019.05+) can be
dropped inside an expression. `assert(condition, "message")` (2019.05+) halts the render —
put one on every parameter with a valid range and on every geometric precondition.

```openscad
module gear(teeth) { assert(teeth >= 5, "gear: need at least 5 teeth"); … }
```

**include vs use**: `include <file.scad>` pastes the file in — its top-level geometry renders
and its variables become overridable defaults. `use <file.scad>` imports only its modules and
functions, running no geometry. Use `use` for libraries unless the library says otherwise.
Paths use `/` on every platform.

**import/export**:

```openscad
import("part.stl", convexity = 3);          // STL | OFF | AMF | 3MF
import("outline.svg", convexity = 3);       // DXF | SVG -> 2D
surface(file = "map.dat" | "map.png", center = false, invert = false, convexity = 5);
```

Command line:

```bash
openscad -o out.stl --hardwarnings model.scad
openscad -o out.png --camera=0,0,0,55,0,25,140 --imgsize=1200,900 model.scad
openscad -o out.stl -D 'width=50' -D 'mode="print_plate"' model.scad
openscad -o out.stl -p params.json -P preset_name model.scad
```

`-D` assignments are appended to the end of the script, which is exactly why variables are
override-able constants.
