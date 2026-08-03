#!/usr/bin/env python3
"""Static sanity check for OpenSCAD scripts.

This is a lint, not a renderer. It catches the mistakes that stop a file from parsing or
that reliably indicate a bug, without evaluating any geometry. It cannot prove a model is
manifold -- if the `openscad` CLI is available, prefer:

    openscad -o /tmp/out.stl --hardwarnings model.scad

Usage:
    python3 scad_check.py model.scad [more.scad ...]

Exit status: 0 clean or warnings only, 1 if any error was found.
"""

import re
import sys

# Built-in modules and functions of OpenSCAD 2021.01, plus deprecated names handled below.
BUILTIN_MODULES = {
    "circle", "square", "polygon", "text", "import", "import_dxf", "import_stl",
    "projection", "offset", "fill",
    "cube", "sphere", "cylinder", "polyhedron", "surface",
    "linear_extrude", "rotate_extrude",
    "translate", "rotate", "scale", "resize", "mirror", "multmatrix", "color",
    "hull", "minkowski", "union", "difference", "intersection", "render",
    "for", "intersection_for", "if", "else", "let", "each", "assign",
    "echo", "assert", "children", "include", "use", "group",
}
BUILTIN_FUNCTIONS = {
    "abs", "sign", "sin", "cos", "tan", "asin", "acos", "atan", "atan2",
    "floor", "round", "ceil", "ln", "len", "let", "log", "pow", "sqrt", "exp",
    "rands", "min", "max", "norm", "cross", "concat", "lookup", "str", "chr", "ord",
    "search", "version", "version_num", "parent_module", "echo", "assert",
    "is_undef", "is_bool", "is_num", "is_string", "is_list", "is_function",
    "dxf_cross", "dxf_dim", "function",
}
KEYWORDS = {"if", "else", "for", "let", "each", "module", "function", "include", "use",
            "true", "false", "undef", "echo", "assert", "intersection_for", "assign"}

DEPRECATED = [
    (r"\btriangles\s*=", "polyhedron(triangles=) is deprecated -- use faces= (2014.03+)"),
    (r"\bassign\s*\(", "assign() is deprecated -- since 2015.03 assign in any scope directly"),
    (r"\bimport_dxf\s*\(", "import_dxf() is deprecated -- use import()"),
    (r"\bimport_stl\s*\(", "import_stl() is deprecated -- use import()"),
]

PAIRS = {")": "(", "]": "[", "}": "{"}
OPENERS = set(PAIRS.values())


def strip_noise(src):
    """Blank out comments and string bodies, preserving line structure and offsets."""
    out = list(src)
    i, n = 0, len(src)
    while i < n:
        c = src[i]
        if c == '"':
            j = i + 1
            while j < n:
                if src[j] == "\\":
                    j += 2
                    continue
                if src[j] == '"':
                    break
                j += 1
            for k in range(i + 1, min(j, n)):
                if out[k] != "\n":
                    out[k] = " "
            i = j + 1
        elif src.startswith("//", i):
            j = src.find("\n", i)
            j = n if j == -1 else j
            for k in range(i, j):
                out[k] = " "
            i = j
        elif src.startswith("/*", i):
            j = src.find("*/", i + 2)
            j = n if j == -1 else j + 2
            for k in range(i, j):
                if out[k] != "\n":
                    out[k] = " "
            i = j
        else:
            i += 1
    return "".join(out)


def line_of(src, pos):
    return src.count("\n", 0, pos) + 1


def check_delimiters(code, src, errors):
    stack = []
    for i, c in enumerate(code):
        if c in OPENERS:
            stack.append((c, i))
        elif c in PAIRS:
            if not stack:
                errors.append((line_of(src, i), f"stray closing '{c}'"))
            elif stack[-1][0] != PAIRS[c]:
                o, oi = stack[-1]
                errors.append((line_of(src, i),
                               f"'{c}' closes '{o}' opened on line {line_of(src, oi)}"))
                stack.pop()
            else:
                stack.pop()
    for o, oi in stack:
        errors.append((line_of(src, oi), f"'{o}' is never closed"))


def check_quotes(src, errors):
    for ln, line in enumerate(src.split("\n"), 1):
        if line.lstrip().startswith("//"):
            continue
        body = line.split("//")[0]
        if len(re.findall(r'(?<!\\)"', body)) % 2:
            errors.append((ln, "odd number of double quotes on this line"))


def check_deprecated(code, src, warnings):
    for pat, msg in DEPRECATED:
        for m in re.finditer(pat, code):
            warnings.append((line_of(src, m.start()), msg))


def check_self_assignment(code, src, warnings):
    """`a = a + 1;` never works -- variables are compile-time constants."""
    for m in re.finditer(r"^[ \t]*([A-Za-z_$][\w$]*)\s*=\s*([^;{]*);", code, re.M):
        name, rhs = m.group(1), m.group(2)
        if re.search(rf"\b{re.escape(name)}\b", rhs):
            warnings.append((line_of(src, m.start()),
                             f"'{name}' refers to itself -- OpenSCAD variables are "
                             f"compile-time constants; use let(), for, or recursion"))


def check_redefined(code, src, warnings):
    seen = {}
    for m in re.finditer(r"^[ \t]*([A-Za-z_$][\w$]*)\s*=\s*[^;{]*;", code, re.M):
        name, ln = m.group(1), line_of(src, m.start())
        if name in seen:
            warnings.append((ln, f"'{name}' reassigned (first set on line {seen[name]}) -- "
                                 f"the LAST assignment wins everywhere in this scope"))
        seen[name] = ln


def check_minkowski(code, src, warnings):
    for m in re.finditer(r"\bminkowski\s*\(", code):
        chunk = code[m.start():m.start() + 400]
        for f in re.finditer(r"\$fn\s*=\s*(\d+)", chunk):
            if int(f.group(1)) >= 50:
                warnings.append((line_of(src, m.start()),
                                 f"minkowski() with $fn={f.group(1)} nearby -- cost is the "
                                 f"PRODUCT of the children's facet counts; keep it <= 24 or "
                                 f"use offset()+linear_extrude()"))
                break


def check_rotate_extrude(code, src, warnings):
    for m in re.finditer(r"\brotate_extrude\s*\(", code):
        chunk = code[m.start():m.start() + 300]
        for t in re.finditer(r"translate\s*\(\s*\[\s*(-[\d.]+)", chunk):
            warnings.append((line_of(src, m.start()),
                             f"rotate_extrude() child translated to x={t.group(1)} -- every "
                             f"vertex must be x >= 0 or the extrusion is silently ignored"))
            break


def check_unknown_calls(code, src, warnings):
    if re.search(r"^\s*(include|use)\s*<", code, re.M):
        return  # a library is in play; we cannot know what it defines
    defined_m = set(re.findall(r"\bmodule\s+([A-Za-z_$][\w$]*)", code))
    defined_f = set(re.findall(r"\bfunction\s+([A-Za-z_$][\w$]*)", code))
    known = defined_m | defined_f | BUILTIN_MODULES | BUILTIN_FUNCTIONS | KEYWORDS
    reported = set()
    for m in re.finditer(r"\b([A-Za-z_$][\w$]*)\s*\(", code):
        name = m.group(1)
        if name in known or name in reported:
            continue
        reported.add(name)
        warnings.append((line_of(src, m.start()),
                         f"'{name}(...)' is not defined in this file and is not a built-in "
                         f"-- typo, or a missing include/use?"))


def report(path, src):
    code = strip_noise(src)
    errors, warnings = [], []

    check_quotes(src, errors)
    check_delimiters(code, src, errors)
    check_deprecated(code, src, warnings)
    check_self_assignment(code, src, warnings)
    check_redefined(code, src, warnings)
    check_minkowski(code, src, warnings)
    check_rotate_extrude(code, src, warnings)
    check_unknown_calls(code, src, warnings)

    print(f"\n=== {path} ===")
    for ln, msg in sorted(errors):
        print(f"  ERROR   line {ln}: {msg}")
    for ln, msg in sorted(warnings):
        print(f"  warning line {ln}: {msg}")

    mods = re.findall(r"\bmodule\s+([A-Za-z_$][\w$]*)", code)
    funs = re.findall(r"\bfunction\s+([A-Za-z_$][\w$]*)", code)
    print(f"  -- {len(mods)} module(s), {len(funs)} function(s), "
          f"{len(errors)} error(s), {len(warnings)} warning(s)")
    if not errors and not warnings:
        print("  no issues found (this does NOT prove the model is manifold -- render it)")
    return len(errors)


def main(argv):
    if len(argv) < 2:
        print(__doc__)
        return 2
    bad = 0
    for path in argv[1:]:
        try:
            with open(path, encoding="utf-8") as fh:
                bad += report(path, fh.read())
        except OSError as e:
            print(f"  ERROR   cannot read {path}: {e}")
            bad += 1
    print()
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
