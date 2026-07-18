# Construction patterns for complex figures

Copy-adaptable recipes. Each one is self-contained vanilla OpenSCAD (no libraries).

**Contents**
1. [Rounded box, rounded plate](#1-rounded-box-rounded-plate)
2. [Fillets and rounds with offset()](#2-fillets-and-rounds-with-offset)
3. [Organic shapes with hull()](#3-organic-shapes-with-hull)
4. [skin() — loft a stack of rings](#4-skin--loft-a-stack-of-rings)
5. [Sweep a profile along a 3D path](#5-sweep-a-profile-along-a-3d-path)
6. [Helices, springs and threads](#6-helices-springs-and-threads)
7. [Arrays: grid, polar, mirrored](#7-arrays-grid-polar-mirrored)
8. [Recursive fractals](#8-recursive-fractals)
9. [Solid heightfield z = f(x,y)](#9-solid-heightfield-z--fxy)
10. [Shells and hollowing](#10-shells-and-hollowing)
11. [Text: engrave, emboss, wrap](#11-text-engrave-emboss-wrap)
12. [Surfaces of revolution](#12-surfaces-of-revolution)
13. [Assembly, section view, print plate](#13-assembly-section-view-print-plate)

---

## 1. Rounded box, rounded plate

Three ways, cheapest first. Prefer the first.

```openscad
// (a) 2D offset + extrude — fast. Rounds the vertical edges only.
module rbox(size, r) {
    linear_extrude(size.z)
        offset(r = r) offset(delta = -r)
            square([size.x, size.y], center = true);
}

// (b) hull of 8 spheres — rounds every edge and corner. Good default for a "soft" box.
module rbox3d(size, r) {
    hull() for (x = [-1, 1], y = [-1, 1], z = [-1, 1])
        translate([x * (size.x/2 - r), y * (size.y/2 - r), z * (size.z/2 - r)])
            sphere(r);
}

// (c) minkowski — elegant, but expensive and it GROWS the object by r in every direction.
//     Compensate in the cube size or the part comes out oversized.
module rbox_mink(size, r) {
    minkowski() {
        cube([size.x - 2*r, size.y - 2*r, size.z - 2*r], center = true);
        sphere(r, $fn = 24);
    }
}
```

`offset(r=r) offset(delta=-r)` (shrink then round out) keeps the outer dimension exactly
`size`; a bare `offset(r=r) square(...)` grows it by `r`.

## 2. Fillets and rounds with offset()

`offset()` is 2D only (2015.03+), which is precisely why profile-first modelling wins: fillet
the 2D profile, then extrude.

```openscad
// Round outside (convex) corners; walls thinner than 2r vanish.
module round2d(r) { offset(r = +r) offset(delta = -r) children(); }

// Fillet inside (concave) corners; holes smaller than 2r vanish.
module fillet2d(r) { offset(r = -r) offset(delta = +r) children(); }

linear_extrude(10) round2d(3) fillet2d(2) difference() {
    square([40, 25], center = true);
    translate([12, 0]) square([10, 10], center = true);
}
```

A **3D fillet where a boss meets a plate** has no vanilla operator. Subtract a "fillet mask"
— the negative space between a cylinder and a torus corner:

```openscad
// Concave fillet ring at the base of a cylinder of radius R.
module fillet_ring(R, r) {
    rotate_extrude(convexity = 4)
        translate([R, 0])
            difference() {
                square(r);                       // corner block, outside the cylinder
                translate([r, r]) circle(r);     // rounded away
            }
}
boss_r = 6; fil = 2;
union() {
    cube([40, 40, 4], center = true);
    translate([0, 0, 2]) cylinder(h = 15, r = boss_r);
    translate([0, 0, 2]) fillet_ring(boss_r, fil);
}
```

## 3. Organic shapes with hull()

`hull()` fills the convex envelope of its children. Scatter cheap primitives at key points
and let the hull do the modelling — the single best trick for sweeping, organic forms.

```openscad
// A capsule between two arbitrary points.
module capsule(p1, p2, r) { hull() { translate(p1) sphere(r); translate(p2) sphere(r); } }

// A tapered, curved limb: chain hulls between consecutive stations.
stations = [ for (i = [0 : 12])
    let (t = i / 12)
    [ [30 * sin(90 * t), 0, 40 * t], 6 - 4 * t ] ];   // [position, radius]

for (i = [0 : len(stations) - 2])
    hull() {
        translate(stations[i][0])     sphere(stations[i][1]);
        translate(stations[i+1][0])   sphere(stations[i+1][1]);
    }
```

Chained hulls stay convex *locally* while the chain as a whole is concave — that is how you
get non-convex organic shapes out of a convex operator. On 2D children `hull()` uses their
XY projections and returns a 2D result.

## 4. skin() — loft a stack of rings

The general answer for a cross-section that changes along its length. Everything from a boat
hull to a torus knot to a duct transition is a stack of rings.

**Invariant (get this wrong and the model is inside-out):** rings are ordered along the
direction of travel, each ring has the same number of points, and each ring's points are
listed **counter-clockwise as seen from the far end of the stack, looking back along the
direction of travel**. If F12 shows pink faces, reverse the point order in every ring.

```openscad
// Connect a stack of rings (each ring = list of 3D points) into a solid.
// closed = true joins the last ring back to the first and omits the end caps (torus, knot).
module skin(rings, closed = false) {
    n = len(rings[0]);
    m = len(rings);
    assert(n >= 3, "skin: rings need at least 3 points");
    assert(m >= 2, "skin: need at least 2 rings");
    pts = [ for (r = rings) each r ];
    sides = [
        for (i = [0 : m - (closed ? 1 : 2)])
            let (a = i * n, b = ((i + 1) % m) * n)
                for (j = [0 : n - 1])
                    let (k = (j + 1) % n)
                        [a + j, b + j, b + k, a + k]
    ];
    caps = closed ? [] : [
        [ for (j = [0 : n - 1]) j ],
        [ for (j = [n - 1 : -1 : 0]) (m - 1) * n + j ]
    ];
    polyhedron(points = pts, faces = concat(sides, caps), convexity = 10);
}
```

Example — a square that morphs into a circle while it twists (a duct transition):

```openscad
n = 64; m = 40; h = 60;
function blend(t, j) =
    let (a = 360 * j / n,
         circ = 15 * [cos(a), sin(a)],
         sq   = 15 * [max(-1, min(1, 1.4 * cos(a))), max(-1, min(1, 1.4 * sin(a)))])
    (1 - t) * sq + t * circ;

skin([ for (i = [0 : m])
         let (t = i / m, tw = 45 * t)
         [ for (j = [0 : n - 1])
             let (p = blend(t, j))
             [ p.x * cos(tw) - p.y * sin(tw),
               p.x * sin(tw) + p.y * cos(tw),
               h * t ] ] ]);
```

## 5. Sweep a profile along a 3D path

Rings generated by carrying a frame along the path. Feed the result to `skin()`.

```openscad
function unit(v) = v / norm(v);

function _tangent(path, i, closed) =
    let (n = len(path),
         p = closed ? path[(i - 1 + n) % n] : path[max(i - 1, 0)],
         q = closed ? path[(i + 1) % n]     : path[min(i + 1, n - 1)])
    unit(q - p);

// Right-handed frame [right, up, tangent]. `ref` must never be parallel to the tangent.
function _frame(t, ref) =
    assert(norm(cross(ref, t)) > 1e-6, "sweep: ref vector is parallel to the path tangent")
    let (r = unit(cross(ref, t)))
    [r, cross(t, r), t];

// profile: list of [x,y] in CCW order.  path: list of [x,y,z].
function sweep_rings(profile, path, ref = [0, 0, 1], closed = false) =
    [ for (i = [0 : len(path) - 1])
        let (t = _tangent(path, i, closed),
             f = _frame(t, ref))
        [ for (p = profile) path[i] + p.x * f[0] + p.y * f[1] ] ];

// --- a trefoil knot in round tube ---
steps = 200;
knot = [ for (i = [0 : steps - 1])
    let (u = 360 * i / steps)
    [ sin(u) + 2 * sin(2 * u),
      cos(u) - 2 * cos(2 * u),
      -sin(3 * u) ] * 8 ];
tube = [ for (k = [0 : 15]) 2.5 * [cos(360 * k / 16), sin(360 * k / 16)] ];

skin(sweep_rings(tube, knot, ref = [0, 0, 1], closed = true), closed = true);
```

Notes: this is a *fixed-reference* frame, which is stable and torsion-free for paths that do
not turn parallel to `ref`; for a path that loops over the top, pass a different `ref` or
switch to BOSL2's `path_sweep()`, which carries a proper rotation-minimizing frame. Sample
the path densely enough that the tube does not self-intersect on tight curves — CGAL reports
self-intersection as a cryptic error, not as a helpful message.

## 6. Helices, springs and threads

```openscad
// (a) Twisted column — cheapest, but the cross-section stays perpendicular to Z.
linear_extrude(height = 80, twist = 720, slices = 200, $fn = 60)
    translate([6, 0]) circle(4);

// (b) True helical spring — the profile stays perpendicular to the wire. Use the sweep.
turns = 5; coil_r = 15; wire_r = 2.5; pitch = 8; seg = 40 * turns;
helix = [ for (i = [0 : seg])
    let (a = 360 * turns * i / seg)
    [ coil_r * cos(a), coil_r * sin(a), pitch * turns * i / seg ] ];
wire = [ for (k = [0 : 11]) wire_r * [cos(30 * k), sin(30 * k)] ];
skin(sweep_rings(wire, helix, ref = [0, 0, 1]));

// (c) Trapezoidal thread — sweep a thread profile, then intersect with the shaft envelope.
//     For real ISO/UTS threads use BOSL2 threading.scad; getting the profile right by hand
//     is a lot of work for a solved problem.
```

`linear_extrude(twist=)` follows the **left** hand rule, and `slices` defaults low — set it
explicitly or the twist comes out faceted.

## 7. Arrays: grid, polar, mirrored

```openscad
module grid(nx, ny, sx, sy) {
    for (i = [0 : nx - 1], j = [0 : ny - 1])
        translate([(i - (nx - 1) / 2) * sx, (j - (ny - 1) / 2) * sy, 0]) children();
}

module polar(n, r, tilt = 0) {
    for (i = [0 : n - 1])
        rotate([0, 0, 360 * i / n]) translate([r, 0, 0]) rotate([0, tilt, 0]) children();
}

// mirror() replaces the object; this keeps both halves.
module mirror_copy(v) { children(); mirror(v) children(); }

difference() {
    cylinder(h = 6, r = 40);
    polar(12, 30) cylinder(h = 6 + 0.02, r = 3, center = true);
}
```

Operator modules take `children()`; `$children` is the count and `children(i)` picks one.
This is what makes arrays composable — `polar(6, 20) mirror_copy([1,0,0]) rib();` reads as a
sentence.

## 8. Recursive fractals

Recursion is by module, and the base case is mandatory — there is no stack guard.

```openscad
// Menger sponge. level 3 is ~9 s; level 4 will make you regret it.
module menger(size, level) {
    if (level <= 0) cube(size, center = true);
    else {
        s = size / 3;
        for (x = [-1, 0, 1], y = [-1, 0, 1], z = [-1, 0, 1])
            if (abs(x) + abs(y) + abs(z) > 1)
                translate([x, y, z] * s) menger(s, level - 1);
    }
}
menger(45, 3);

// Recursive tree — branches taper and shorten each generation.
module branch(len, r, level) {
    cylinder(h = len, r1 = r, r2 = r * 0.7);
    if (level > 0)
        translate([0, 0, len])
            for (a = [0 : 120 : 359])
                rotate([0, 30, a + 20 * level])
                    branch(len * 0.72, r * 0.7, level - 1);
}
branch(30, 3, 4);
```

Cost is exponential — count the leaves before rendering. Gate the depth on `$preview` if the
final level is slow.

## 9. Solid heightfield `z = f(x,y)`

For data in a file, `surface(file = "data.dat")` or a PNG heightmap is simpler. Use this when
the surface is a formula. **Trig is in degrees.**

```openscad
nx = 60; ny = 60; sx = 80; sy = 80; z0 = -4;
function fz(x, y) = 6 * cos(6 * x) * sin(6 * y);

function X(i) = sx * i / nx - sx / 2;
function Y(j) = sy * j / ny - sy / 2;

module heightfield() {
    N   = (nx + 1) * (ny + 1);
    top = [ for (i = [0 : nx], j = [0 : ny]) [X(i), Y(j), fz(X(i), Y(j))] ];
    bot = [ for (i = [0 : nx], j = [0 : ny]) [X(i), Y(j), z0] ];
    faces = concat(
        [ for (i = [0 : nx - 1], j = [0 : ny - 1])       // top surface
            [ i*(ny+1)+j, i*(ny+1)+j+1, (i+1)*(ny+1)+j+1, (i+1)*(ny+1)+j ] ],
        [ for (i = [0 : nx - 1], j = [0 : ny - 1])       // flat base
            [ N + i*(ny+1)+j, N + (i+1)*(ny+1)+j, N + (i+1)*(ny+1)+j+1, N + i*(ny+1)+j+1 ] ],
        [ for (j = [0 : ny - 1]) [ j, N + j, N + j + 1, j + 1 ] ],                     // -X wall
        [ for (j = [0 : ny - 1]) let (o = nx*(ny+1))
            [ o+j, o+j+1, N+o+j+1, N+o+j ] ],                                          // +X wall
        [ for (i = [0 : nx - 1])
            [ i*(ny+1), (i+1)*(ny+1), N + (i+1)*(ny+1), N + i*(ny+1) ] ],              // -Y wall
        [ for (i = [0 : nx - 1]) let (o = ny)
            [ i*(ny+1)+o, N + i*(ny+1)+o, N + (i+1)*(ny+1)+o, (i+1)*(ny+1)+o ] ]       // +Y wall
    );
    polyhedron(points = concat(top, bot), faces = faces, convexity = 10);
}
heightfield();
```

## 10. Shells and hollowing

```openscad
// Shell a profile-based part: offset inward, don't guess at inner dimensions.
wall = 2;
linear_extrude(30) difference() {
    round2d(4) square([50, 30], center = true);
    offset(delta = -wall) round2d(4) square([50, 30], center = true);
}

// Shell an arbitrary solid: subtract a scaled copy. Only correct for shapes centred on the
// origin and roughly uniform — scale() thins the walls unevenly. Prefer the offset route.
difference() { part(); scale(0.9) part(); }

// Open-topped box: difference the cavity, leave the floor.
difference() {
    rbox([50, 30, 25], 3);
    translate([0, 0, wall]) rbox([50 - 2*wall, 30 - 2*wall, 25], 3 - wall/2);
}
```

## 11. Text: engrave, emboss, wrap

```openscad
// Engrave — the classic mistake is a zero-depth cut that vanishes in the slicer.
depth = 0.6;
difference() {
    cube([60, 20, 5], center = true);
    translate([0, 0, 2.5 - depth + 0.01])
        linear_extrude(depth + 0.02)
            text("OPENSCAD", size = 8, halign = "center", valign = "center",
                 font = "Liberation Sans:style=Bold");
}

// Emboss on a cylinder — bend each glyph by intersecting a radial slab with the shell.
module label_on_cylinder(txt, r, h, size = 6, depth = 0.8) {
    chars = len(txt);
    span  = 180;
    for (i = [0 : chars - 1])
        rotate([0, 0, span * (i / (chars - 1) - 0.5)])
            intersection() {
                difference() { cylinder(h = h, r = r + depth); cylinder(h = h, r = r); }
                translate([r, 0, h/2]) rotate([90, 0, 90])
                    linear_extrude(depth + 1, center = true)
                        text(txt[i], size = size, halign = "center", valign = "center");
            }
}
```

`text()` needs 2015.03+. Stick to the bundled Liberation fonts unless the user names one —
a missing font silently falls back and ruins the dimensions.

## 12. Surfaces of revolution

```openscad
// Vase from a profile. The profile must lie entirely at x >= 0.
n = 60; H = 120;
profile = concat(
    [[0, 0]],
    [ for (i = [0 : n])
        let (t = i / n) [ 20 + 12 * sin(180 * t) + 4 * sin(720 * t), H * t ] ],
    [[0, H]]
);
rotate_extrude($fn = 160, convexity = 6) polygon(profile);
```

`rotate_extrude` sweeps the profile's XY projection around Z. Every vertex must be `x >= 0`
(or all `x <= 0`); a profile that crosses the Y axis is silently ignored with a console
warning. Touching the axis is fine only along a *line*, never at a single point. The `angle`
parameter (2019.05+) makes partial sweeps — hooks, elbows, C-clips.

## 13. Assembly, section view, print plate

```openscad
mode = "assembled"; // [assembled, exploded, print_plate, section]

module lid()  { … }
module base() { … }

if (mode == "assembled") { base(); translate([0, 0, 20]) lid(); }
else if (mode == "exploded") { base(); translate([0, 0, 45]) lid(); }
else if (mode == "print_plate") { base(); translate([60, 0, 0]) rotate([180, 0, 0]) lid(); }
else if (mode == "section")
    difference() {
        union() { base(); translate([0, 0, 20]) lid(); }
        translate([-100, 0, -100]) cube(200);   // cut away half
    }
```

One file, one part family, one `mode` — better than four files that drift apart. Ship the
print plate with parts flat-side-down and no supports needed.
