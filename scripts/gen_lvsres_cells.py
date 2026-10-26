# Generates the lvsres LVS test layouts: a two-turn spiral inductor and a stacked
# transformer balun for ihp-sg13g2 and ihp-sg13cmos5l, and copies of them broken on purpose
# for ihp-sg13g2.
#
# Run with KLayout in the IIC-OSIC-TOOLS container:
#     klayout -b -r scripts/gen_lvsres_cells.py [-rd out=<repo root>]
#
# Metal resistors (lvsres) break the coil into nets, so LVS can see which pin sits on which
# lead. On ihp-sg13g2 they are instances of the lvsres PCell of the SG13_dev library, as a
# designer would place them, which needs IHP-Open-PDK#1121. ihp-sg13cmos5l has no lvsres
# PCell, so its markers are drawn as <metal>/29 rectangles over the trace.
#
# SPDX-FileCopyrightText: 2026 Julian Schwarz and Simon Dorrer
# Johannes Kepler University, Department for Integrated Circuits
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1

import math
import os
import sys

import pya

OUT = globals().get("out") or os.path.join(os.path.dirname(os.path.realpath(__file__)), "..")

UM = 1000  # dbu per um, dbu = 1 nm
GRID = 5   # manufacturing grid in dbu

# GDS layer numbers, used with datatype 0 (drawing), 2 (pin), 25 (text) and 29 (res).
# Metal4 and TopMetal1 have the same numbers in both PDKs.
LAYERS = {
    "Metal4": 50,
    "TopMetal1": 126,
    "TopMetal2": 134,
}
VIAS = {
    # name: (gds layer, cut size, cut space in um, n for an n x n array that keeps the
    # enclosure rules inside the end of a 4 um trace)
    "TopVia1": (125, 0.42, 0.42, 4),
    "TopVia2": (133, 0.90, 1.06, 2),
}
# Marker length per layer, fixed by the lvs_format of sg13g2_pr/lvsres.sym
RES_LENGTH = {"TopMetal2": 2.0, "TopMetal1": 1.64, "Metal4": 1.0}

STACKS = {
    # coil metal, underpass or secondary metal, via between them
    "ihp-sg13g2": ("TopMetal2", "TopMetal1", "TopVia2"),
    "ihp-sg13cmos5l": ("TopMetal1", "Metal4", "TopVia1"),
}


def snap(v):
    return int(round(v / GRID)) * GRID


def dbu(v_um):
    return snap(v_um * UM)


# ---------------------------------------------------------------------------------------------
# Octilinear path to polygon
#
# Every segment runs in one of the 8 directions. Each segment contributes two offset lines
# n.q = c +- s, with s = w/2 for axis segments and s = w/sqrt(2) (snapped) for diagonals. A
# vertex is the intersection of the offset lines of two consecutive segments, and since every
# turn pairs an axis line with a diagonal one (or two axis lines), it lands on the grid with
# exact 45 degree edges.
# ---------------------------------------------------------------------------------------------
def _seg_dir(p, q):
    dx, dy = q[0] - p[0], q[1] - p[1]
    sx = (dx > 0) - (dx < 0)
    sy = (dy > 0) - (dy < 0)
    assert dx == 0 or dy == 0 or abs(dx) == abs(dy), f"segment {p}->{q} is not octilinear"
    return sx, sy


def _line(p, d, side, w):
    # left normal n = (-dy, dx), the line constant moves by side * s along it
    n = (-d[1], d[0])
    diag = d[0] != 0 and d[1] != 0
    s = snap(w / math.sqrt(2)) if diag else w // 2
    return n, n[0] * p[0] + n[1] * p[1] + side * s


def _cross(l1, l2):
    (a1, b1), c1 = l1
    (a2, b2), c2 = l2
    det = a1 * b2 - a2 * b1
    assert abs(det) == 1, "turn between two diagonals or collinear segments"
    x = (c1 * b2 - c2 * b1) // det
    y = (a1 * c2 - a2 * c1) // det
    return x, y


def path_polygon(pts, w):
    dirs = [_seg_dir(pts[i], pts[i + 1]) for i in range(len(pts) - 1)]
    assert 0 in dirs[0] and 0 in dirs[-1], "first and last segment must be axis aligned"
    sides = []
    for side in (1, -1):
        lines = [_line(pts[i], dirs[i], side, w) for i in range(len(dirs))]
        d0, dn = dirs[0], dirs[-1]
        start = (pts[0][0] - d0[1] * side * w // 2, pts[0][1] + d0[0] * side * w // 2)
        end = (pts[-1][0] - dn[1] * side * w // 2, pts[-1][1] + dn[0] * side * w // 2)
        sides.append([start] + [_cross(lines[i], lines[i + 1]) for i in range(len(lines) - 1)] + [end])
    ring = sides[0] + sides[1][::-1]
    return pya.Polygon([pya.Point(x, y) for x, y in ring])


def octagon(r, k):
    # centerline vertices of an octagon with side lines |x| = r, |y| = r and |x| + |y| = k,
    # counterclockwise, starting where the bottom side meets the bottom-right diagonal
    return [(k - r, -r), (r, r - k), (r, k - r), (k - r, r), (r - k, r), (-r, k - r), (-r, r - k), (r - k, -r)]


# ---------------------------------------------------------------------------------------------
# Layout helpers
# ---------------------------------------------------------------------------------------------
class Cell:
    def __init__(self, ly, name, pdk):
        self.ly = ly
        self.cell = ly.create_cell(name)
        self.pdk = pdk

    def shape(self, layer, dt, shape):
        self.cell.shapes(self.ly.layer(layer, dt)).insert(shape)

    def box(self, layer, dt, x1, y1, x2, y2):
        self.shape(layer, dt, pya.Box(dbu(x1), dbu(y1), dbu(x2), dbu(y2)))

    def pin(self, metal, name, x, y, w, h):
        # pin shape on <metal>/2 and the label on <metal>/25, as in the other regression cells
        layer = LAYERS[metal]
        self.box(layer, 2, x - w / 2, y - h / 2, x + w / 2, y + h / 2)
        self.shape(layer, 25, pya.Text(name, pya.Trans(pya.Point(dbu(x), dbu(y)))))

    def via_array(self, via, x, y):
        layer, size, space, n = VIAS[via]
        pitch = size + space
        for i in range(n):
            for j in range(n):
                cx = x + (i - (n - 1) / 2) * pitch
                cy = y + (j - (n - 1) / 2) * pitch
                self.box(layer, 0, cx - size / 2, cy - size / 2, cx + size / 2, cy + size / 2)

    def lvsres(self, metal, x, y, w, vertical):
        # metal resistor of width w (across the trace) centred on (x, y), its length along y
        # for a vertical trace and along x for a horizontal one. Call it after the trace is drawn.
        length = RES_LENGTH[metal]
        hl, hw = length / 2, w / 2
        if vertical:
            body = pya.Box(dbu(x - hw), dbu(y - hl), dbu(x + hw), dbu(y + hl))
        else:
            body = pya.Box(dbu(x - hl), dbu(y - hw), dbu(x + hl), dbu(y + hw))
        if self.pdk != "ihp-sg13g2":
            self.shape(LAYERS[metal], 29, body)
            return
        pc = self.ly.create_cell("lvsres", "SG13_dev", {"layer": metal, "width": f"{w}u", "length": f"{length}u"})
        assert pc is not None, "SG13_dev has no lvsres PCell, is IHP-Open-PDK#1121 installed?"
        # the PCell body spans x in [-l/2, l/2] and y in [0, w]
        if vertical:
            t = pya.Trans(dbu(x + w / 2), dbu(y)) * pya.Trans.R90
        else:
            t = pya.Trans(dbu(x), dbu(y - w / 2))
        self.cell.insert(pya.CellInstArray(pc.cell_index(), t))
        # Cut the trace under the resistor body, the PCell's own metal bridges the gap. Magic DRC
        # rejects trace metal that overlaps the resistor of a subcell ("Can't overlap those layers").
        shapes = self.cell.shapes(self.ly.layer(LAYERS[metal], 0))
        rest = pya.Region(shapes) - pya.Region(body)
        shapes.clear()
        shapes.insert(rest)


def new_layout(pdk):
    ly = pya.Layout()
    ly.dbu = 1.0 / UM
    if pdk == "ihp-sg13g2":
        ly.technology_name = "sg13g2"  # SG13_dev is registered for this technology
    return ly


def write(ly, pdk, name):
    opts = pya.SaveLayoutOptions()
    opts.gds2_write_timestamps = False  # keep regenerated layouts byte-identical
    opts.write_context_info = False     # plain shapes, every tool reads the layout as drawn
    path = os.path.join(OUT, pdk, "layout", f"{name}.gds")
    ly.write(path, opts)
    print(f"wrote {path}")


# ---------------------------------------------------------------------------------------------
# Inductor: two-turn octagonal spiral on the coil metal, inner end taken out on the underpass
# metal. LA is the outer lead (coil metal), LB the underpass lead. One lvsres on each lead.
# ---------------------------------------------------------------------------------------------
W = 4.0       # trace width
S = 4.0       # turn spacing
R1 = 50.0     # outer turn centerline half width
Y_PIN = -65.0


def inductor(pdk, name, swap_pins=False, no_res=False):
    coil, under, via = STACKS[pdk]
    ly = new_layout(pdk)
    c = Cell(ly, name, pdk)

    r1, r2 = dbu(R1), dbu(R1 - W - S)
    k1, k2 = snap(r1 * math.sqrt(2)), snap(r2 * math.sqrt(2))
    xa, xj, xv = dbu(8.0), dbu(-6.0), dbu(-10.5)  # LA lead, outer-to-inner jog, inner via
    w = dbu(W)

    o1, o2 = octagon(r1, k1), octagon(r2, k2)
    pts = [(xa, dbu(Y_PIN)), (xa, -r1)] + o1 + [(xj, -r1), (xj + (r1 - r2), -r2)] + o2 + [(xv + w // 2, -r2)]
    c.shape(LAYERS[coil], 0, path_polygon(pts, w))

    # inner end: via array onto the underpass, which runs down below the outer turn
    vx, vy = xv / UM, -r2 / UM
    c.via_array(via, vx, vy)
    c.box(LAYERS[under], 0, vx - W / 2, Y_PIN, vx + W / 2, vy + W / 2)

    if not no_res:
        c.lvsres(coil, xa / UM, Y_PIN + 6.0, W, vertical=True)
        c.lvsres(under, vx, Y_PIN + 5.0, W, vertical=True)

    la, lb = ("LB", "LA") if swap_pins else ("LA", "LB")
    c.pin(coil, la, xa / UM, Y_PIN + 0.5, W, 1.0)
    c.pin(under, lb, vx, Y_PIN + 0.5, W, 1.0)
    write(ly, pdk, name)


# ---------------------------------------------------------------------------------------------
# Balun: stacked transformer. Primary P1/P2 is one octagonal turn on the coil metal, open at
# the bottom. Secondary S1/S2 is one turn on the metal below, open at the top, with its centre
# tap CT taken out at the bottom. lvsres on the P1 lead and on both sides of the secondary ring,
# so the secondary reads S1 - CT - S2.
# ---------------------------------------------------------------------------------------------
RB = 40.0     # centerline half width of both turns
G = 6.0       # lead offset from the centre line
Y_TOP = 60.0
Y_BOT = -60.0


def balun(pdk, name, swap_pins=False):
    top, low, _ = STACKS[pdk]
    ly = new_layout(pdk)
    c = Cell(ly, name, pdk)

    r = dbu(RB)
    k = snap(r * math.sqrt(2))
    g, w = dbu(G), dbu(W)
    oc = octagon(r, k)

    # primary, clockwise from P1: up the left lead, around, down the right lead
    prim = [(-g, dbu(Y_BOT)), (-g, -r)] + oc[::-1] + [(g, -r), (g, dbu(Y_BOT))]
    c.shape(LAYERS[top], 0, path_polygon(prim, w))
    # secondary, counterclockwise from S1: down the left lead, around, up the right lead
    sec = [(-g, dbu(Y_TOP)), (-g, r)] + oc[4:] + oc[:4] + [(g, r), (g, dbu(Y_TOP))]
    c.shape(LAYERS[low], 0, path_polygon(sec, w))
    # centre tap: stub down from the middle of the bottom side
    c.box(LAYERS[low], 0, -W / 2, Y_BOT, W / 2, -RB)

    c.lvsres(top, -G, Y_BOT + 7.0, W, vertical=True)
    c.lvsres(low, -RB, 0.0, W, vertical=True)
    c.lvsres(low, RB, 0.0, W, vertical=True)

    s1, s2 = ("CT", "S1") if swap_pins else ("S1", "CT")
    c.pin(top, "P1", -G, Y_BOT + 0.5, W, 1.0)
    c.pin(top, "P2", G, Y_BOT + 0.5, W, 1.0)
    c.pin(low, s1, -G, Y_TOP - 0.5, W, 1.0)
    c.pin(low, s2, 0.0, Y_BOT + 0.5, W, 1.0)
    c.pin(low, "S2", G, Y_TOP - 0.5, W, 1.0)
    write(ly, pdk, name)


def load_pcells():
    base = os.path.join(os.environ.get("PDK_ROOT", "/foss/pdks"), "ihp-sg13g2", "libs.tech", "klayout", "python")
    # klayout -b runs no autorun macros, so the SG13_dev library has to be registered here
    sys.path[:0] = [base, os.path.join(base, "pycell4klayout-api", "source", "python")]
    import sg13g2_pycell_lib  # noqa: F401


load_pcells()

for pdk in STACKS:
    inductor(pdk, "sg13_ind_lvsres")
    balun(pdk, "sg13_balun_lvsres")
# The cells broken on purpose exist for ihp-sg13g2 only. ihp-sg13cmos5l has no
# sg13cmos5l_pr/lvsres.sym yet, so their LVS steps could not reach the check (KNOWN_ISSUES.md).
inductor("ihp-sg13g2", "sg13_ind_lvsres_swap", swap_pins=True)
inductor("ihp-sg13g2", "sg13_ind_lvsres_short", no_res=True)
balun("ihp-sg13g2", "sg13_balun_lvsres_swap", swap_pins=True)
