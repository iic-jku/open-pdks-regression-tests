# Generates dummy metal-only layouts for validating Magic PEX against hand calculations.
# Run: klayout -b -r gen_structures.py

import os
import pya

OUT = os.path.join(os.path.dirname(os.path.realpath(__file__)), "..", "layout")

# KLayout stamps the wall clock into the GDS header unless this is off, which would make every
# regenerated layout differ from the committed one. "make layouts-check" asserts they match.
GDS_OPTS = pya.SaveLayoutOptions()
GDS_OPTS.gds2_write_timestamps = False
os.makedirs(OUT, exist_ok=True)

DBU = 0.001

# GDS numbers from libs.tech/klayout/tech/sg13cmos5l.map, pin datatype 2 carries the port
# labels.
#
# The top layer is named tm1 here, as the KLayout map and sg13g2 both name it: it is GDS 126,
# the same physical thick metal as sg13g2's TopMetal1, with the same 18 mOhm/sq and the same
# 1.64 um minimum width. The Magic extraction deck calls it metal5 instead, because it counts
# conductors and this PDK has five - "calma MET5 126 0" in the cifin tech file is where the two
# namings meet. There is no thin Metal5 in this stack; that layer exists only in sg13g2. So the
# coefficient tables below read allm5 from the deck and store it under tm1.
METAL = {
    "m1": (8, 0, 8, 2),
    "m2": (10, 0, 10, 2),
    "m3": (30, 0, 30, 2),
    "m4": (50, 0, 50, 2),
    "tm1": (126, 0, 126, 2),
}


class Build:
    def __init__(self, name):
        self.name = name
        self.ly = pya.Layout()
        self.ly.dbu = DBU
        self.top = self.ly.create_cell(name)

    def _lay(self, num, dt):
        return self.ly.layer(num, dt)

    def box(self, metal, x0, y0, x1, y1):
        num, dt, _, _ = METAL[metal]
        self.top.shapes(self._lay(num, dt)).insert(
            pya.DBox(x0, y0, x1, y1))

    def port(self, metal, name, xc, yc, size=0.2):
        # A pin box plus a text on the same layer/datatype. The pin datatype is OR'ed into
        # the metal by the cifinput rules, so keep the box inside the drawn shape.
        _, _, pnum, pdt = METAL[metal]
        lay = self._lay(pnum, pdt)
        h = size / 2.0
        self.top.shapes(lay).insert(pya.DBox(xc - h, yc - h, xc + h, yc + h))
        t = pya.DText(name, xc, yc)
        self.top.shapes(lay).insert(t)

    def write(self):
        path = os.path.join(OUT, self.name + ".gds")
        self.ly.write(path, GDS_OPTS)
        print("wrote " + path)


# ---------------------------------------------------------------- A: area + perimeter to substrate
# A wide plate (area dominated) and a thin wire (perimeter dominated) on the same layer,
# 60 um apart so they do not couple. Two shapes give two equations for areacap and perimc.
A_PLATE = (0.0, 0.0, 50.0, 50.0)       # A = 2500 um2, P = 200 um
A_WIRE = (0.0, 110.0, 0.5, 160.0)      # A = 25 um2,   P = 101 um

for m in METAL:
    b = Build("capsub_" + m)
    b.box(m, *A_PLATE)
    b.port(m, "plate", 25.0, 25.0)
    b.box(m, *A_WIRE)
    b.port(m, "wire", 0.25, 135.0, size=0.1)
    b.write()

# ---------------------------------------------------------------- B: vertical overlap between layers
# Small top plate fully inside a large bottom plate: the top plate sees only the bottom plate,
# so its area cap and its edge fringe both land on the bottom net.
PAIRS = [("m1", "m2"), ("m2", "m3"), ("m3", "m4"), ("m4", "tm1"),
         ("m1", "m3"), ("m1", "tm1")]

for lo, up in PAIRS:
    b = Build("overlap_%s_%s" % (lo, up))
    b.box(lo, 0.0, 0.0, 30.0, 30.0)          # A = 900 um2, P = 120 um
    b.port(lo, "bot", 2.0, 2.0)
    b.box(up, 10.0, 10.0, 20.0, 20.0)        # A = 100 um2, P = 40 um
    b.port(up, "top", 15.0, 15.0)
    b.write()

# ---------------------------------------------------------------- C: lateral sidewall coupling
# Two parallel wires, W = 0.5 um, L = 50 um, separation swept.
for s in (0.2, 0.4, 0.8, 1.6, 3.2):
    tag = str(s).replace(".", "p")
    b = Build("sidewall_m1_s" + tag)
    b.box("m1", 0.0, 0.0, 0.5, 50.0)
    b.port("m1", "a", 0.25, 25.0, size=0.1)
    b.box("m1", 0.5 + s, 0.0, 1.0 + s, 50.0)
    b.port("m1", "b", 0.75 + s, 25.0, size=0.1)
    b.write()

# ---------------------------------------------------------------- D: series resistance
# W = 1 um, L = 100 um straight wire, one port at each end: 100 squares.
for m in METAL:
    b = Build("res_" + m)
    b.box(m, 0.0, 0.0, 1.0, 100.0)
    b.port(m, "l", 0.5, 0.5)
    b.port(m, "r", 0.5, 99.5)
    b.write()

print("done")
