import os, pya
OUT = os.path.join(os.path.dirname(os.path.realpath(__file__)), "..", "layout")

# KLayout stamps the wall clock into the GDS header unless this is off, which would make every
# regenerated layout differ from the committed one. "make layouts-check" asserts they match.
GDS_OPTS = pya.SaveLayoutOptions()
GDS_OPTS.gds2_write_timestamps = False
ly = pya.Layout(); ly.dbu = 0.001
top = ly.create_cell("rc_tee_pair_m1")
lm = ly.layer(34, 0); lp = ly.layer(34, 10)
# Two parallel 0.5 um wires 0.2 um apart, each with a stub so both nets branch
# and therefore qualify for resistance extraction at the default threshold.
shapes = [(0.0, 0.0, 0.5, 200.0), (-20.0, 100.0, 0.0, 100.5),
          (0.7, 0.0, 1.2, 200.0), (1.2, 100.0, 21.2, 100.5)]
for b in shapes:
    top.shapes(lm).insert(pya.DBox(*b))
ports = [("a0", 0.25, 0.5), ("b0", 0.25, 199.5), ("s0", -19.5, 100.25),
         ("a1", 0.95, 0.5), ("b1", 0.95, 199.5), ("s1", 20.7, 100.25)]
for (n, x, y) in ports:
    top.shapes(lp).insert(pya.DBox(x-0.1, y-0.1, x+0.1, y+0.1))
    top.shapes(lp).insert(pya.DText(n, x, y))
ly.write(os.path.join(OUT, "rc_tee_pair_m1.gds"), GDS_OPTS); print("ok")
