import os, pya
OUT = os.path.join(os.path.dirname(os.path.realpath(__file__)), "..", "layout")

# KLayout stamps the wall clock into the GDS header unless this is off, which would make every
# regenerated layout differ from the committed one. "make layouts-check" asserts they match.
GDS_OPTS = pya.SaveLayoutOptions()
GDS_OPTS.gds2_write_timestamps = False
def build(name, boxes, ports):
    ly = pya.Layout(); ly.dbu = 0.001
    top = ly.create_cell(name)
    lm = ly.layer(8, 0); lp = ly.layer(8, 2)
    for b in boxes:
        top.shapes(lm).insert(pya.DBox(*b))
    for (n, x, y) in ports:
        top.shapes(lp).insert(pya.DBox(x-0.1, y-0.1, x+0.1, y+0.1))
        top.shapes(lp).insert(pya.DText(n, x, y))
    ly.write(os.path.join(OUT, name + ".gds"), GDS_OPTS); print("wrote " + name)

# 1 um wide, 1000 um long: 1000 squares = 110 Ohm
build("res_long_m1", [(0.0, 0.0, 1.0, 1000.0)], [("l", 0.5, 0.5), ("r", 0.5, 999.5)])
# T junction: three 100 um arms meeting at the centre
build("res_tee_m1",
      [(0.0, 100.0, 200.0, 101.0), (99.5, 0.0, 100.5, 100.0)],
      [("a", 0.5, 100.5), ("b", 199.5, 100.5), ("c", 100.0, 0.5)])
