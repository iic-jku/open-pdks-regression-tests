import os, pya
OUT = os.path.join(os.path.dirname(os.path.realpath(__file__)), "..", "layout")

# KLayout stamps the wall clock into the GDS header unless this is off, which would make every
# regenerated layout differ from the committed one. "make layouts-check" asserts they match.
GDS_OPTS = pya.SaveLayoutOptions()
GDS_OPTS.gds2_write_timestamps = False
# Two parallel M1 wires 0.5 um wide, 200 um long, 0.2 um apart.
# Three ports on each wire so both nets are resistance-extracted at the default threshold.
ly = pya.Layout(); ly.dbu = 0.001
top = ly.create_cell("rc_pair_m1")
lm = ly.layer(34, 0); lp = ly.layer(34, 10)
for i, x0 in enumerate((0.0, 0.7)):
    top.shapes(lm).insert(pya.DBox(x0, 0.0, x0 + 0.5, 200.0))
    for j, y in enumerate((0.5, 100.0, 199.5)):
        n = "%s%d" % ("abc"[j], i)
        top.shapes(lp).insert(pya.DBox(x0+0.15, y-0.1, x0+0.35, y+0.1))
        top.shapes(lp).insert(pya.DText(n, x0+0.25, y))
ly.write(os.path.join(OUT, "rc_pair_m1.gds"), GDS_OPTS); print("wrote rc_pair_m1")
