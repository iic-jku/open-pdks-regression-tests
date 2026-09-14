import os, pya
OUT = os.path.join(os.path.dirname(os.path.realpath(__file__)), "..", "layout")

# KLayout stamps the wall clock into the GDS header unless this is off, which would make every
# regenerated layout differ from the committed one. "make layouts-check" asserts they match.
GDS_OPTS = pya.SaveLayoutOptions()
GDS_OPTS.gds2_write_timestamps = False
def build(name, boxes, ports):
    ly = pya.Layout(); ly.dbu = 0.001
    top = ly.create_cell(name)
    lm = ly.layer(68, 20); lp = ly.layer(68, 16)
    for b in boxes:
        top.shapes(lm).insert(pya.DBox(*b))
    for (n, x, y) in ports:
        top.shapes(lp).insert(pya.DBox(x-0.1, y-0.1, x+0.1, y+0.1))
        top.shapes(lp).insert(pya.DText(n, x, y))
    ly.write(os.path.join(OUT, name + ".gds"), GDS_OPTS); print("wrote " + name)

# Asymmetric tee, 1 um wide arms meeting at (100, 100.5).
# a arm 99.5 um (12.4375 Ohm), b arm 299.5 um (37.4375 Ohm), c arm 200 um (25 Ohm).
build("tee_asym_m1",
      [(0.0, 100.0, 400.0, 101.0), (99.5, -100.0, 100.5, 100.0)],
      [("a", 0.5, 100.5), ("b", 399.5, 100.5), ("c", 100.0, -99.5)])
# Cross with four distinct arm lengths meeting at (200, 200.5)
build("cross_m1",
      [(0.0, 200.0, 500.0, 201.0), (199.5, 0.0, 200.5, 400.0)],
      [("w", 0.5, 200.5), ("e", 499.5, 200.5), ("s", 200.0, 0.5), ("n", 200.0, 399.5)])
