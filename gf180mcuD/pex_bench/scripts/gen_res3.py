import os, pya
OUT = os.path.join(os.path.dirname(os.path.realpath(__file__)), "..", "layout")

# KLayout stamps the wall clock into the GDS header unless this is off, which would make every
# regenerated layout differ from the committed one. "make layouts-check" asserts they match.
GDS_OPTS = pya.SaveLayoutOptions()
GDS_OPTS.gds2_write_timestamps = False
def build(name, boxes, ports):
    ly = pya.Layout(); ly.dbu = 0.001
    top = ly.create_cell(name)
    lm = ly.layer(34, 0); lp = ly.layer(34, 10)
    for b in boxes:
        top.shapes(lm).insert(pya.DBox(*b))
    for (n, x, y) in ports:
        top.shapes(lp).insert(pya.DBox(x-0.1, y-0.1, x+0.1, y+0.1))
        top.shapes(lp).insert(pya.DText(n, x, y))
    ly.write(os.path.join(OUT, name + ".gds"), GDS_OPTS); print("wrote " + name)

# Same 1000 um wire as res_long_m1 but with a third port in the middle.
build("res_long3_m1", [(0.0, 0.0, 1.0, 1000.0)],
      [("l", 0.5, 0.5), ("m", 0.5, 500.0), ("r", 0.5, 999.5)])
