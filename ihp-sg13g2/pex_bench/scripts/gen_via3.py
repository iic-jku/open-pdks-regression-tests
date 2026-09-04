import os, pya
OUT = os.path.join(os.path.dirname(os.path.realpath(__file__)), "..", "layout")

# KLayout stamps the wall clock into the GDS header unless this is off, which would make every
# regenerated layout differ from the committed one. "make layouts-check" asserts they match.
GDS_OPTS = pya.SaveLayoutOptions()
GDS_OPTS.gds2_write_timestamps = False
M = {"m5":(67,0,67,2),"tm1":(126,0,126,2),"tm2":(134,0,134,2)}
V = {("m5","tm1"):(125,0,0.42,0.42),("tm1","tm2"):(133,0,0.90,1.06)}
ARM, PAD = 2.0, 16.0

def build(lo, up, ncuts):
    name = "vp_%s_%s_n%d" % (lo, up, ncuts)
    ly = pya.Layout(); ly.dbu = 0.001
    top = ly.create_cell(name)
    lo_n, lo_d, lo_pn, lo_pd = M[lo]; up_n, up_d, up_pn, up_pd = M[up]
    vn, vd, vs, vsp = V[(lo, up)]
    cx = PAD/2.0
    # narrow arm plus a wide landing pad at the junction, so the cuts fit and the arm still has resistance
    top.shapes(ly.layer(lo_n, lo_d)).insert(pya.DBox(cx-ARM/2, 0.0, cx+ARM/2, 48.0))
    top.shapes(ly.layer(lo_n, lo_d)).insert(pya.DBox(0.0, 48.0, PAD, 52.0))
    top.shapes(ly.layer(up_n, up_d)).insert(pya.DBox(0.0, 48.0, PAD, 52.0))
    top.shapes(ly.layer(up_n, up_d)).insert(pya.DBox(cx-ARM/2, 52.0, cx+ARM/2, 100.0))
    pitch = vs + vsp
    x0 = cx - (ncuts*pitch - vsp)/2.0
    for i in range(ncuts):
        x = x0 + i*pitch
        assert x >= 0.5 and x+vs <= PAD-0.5, (name, x)
        top.shapes(ly.layer(vn, vd)).insert(pya.DBox(x, 50.0-vs/2, x+vs, 50.0+vs/2))
    for (mn, md, nm, y) in [(lo_pn, lo_pd, "l", 0.5), (up_pn, up_pd, "u", 99.5)]:
        top.shapes(ly.layer(mn, md)).insert(pya.DBox(cx-0.1, y-0.1, cx+0.1, y+0.1))
        top.shapes(ly.layer(mn, md)).insert(pya.DText(nm, cx, y))
    ly.write(os.path.join(OUT, name + ".gds"), GDS_OPTS); print("wrote " + name)

for k in V:
    for n in (1, 2, 4, 8):
        build(k[0], k[1], n)
