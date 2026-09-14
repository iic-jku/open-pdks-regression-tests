import os, pya
OUT = os.path.join(os.path.dirname(os.path.realpath(__file__)), "..", "layout")

# KLayout stamps the wall clock into the GDS header unless this is off, which would make every
# regenerated layout differ from the committed one. "make layouts-check" asserts they match.
GDS_OPTS = pya.SaveLayoutOptions()
GDS_OPTS.gds2_write_timestamps = False
M = {"li1":(67,20,67,16),"m1":(68,20,68,16),"m2":(69,20,69,16),"m3":(70,20,70,16),
     "m4":(71,20,71,16),"m5":(72,20,72,16)}
# via layer, cut size, min cut spacing. Unlike the other PDKs the cut size differs per level,
# from mcon at 0.17 um to via4 at 0.8 um (rules ct.1/ct.2, via.1a/via.2, via2.1a/via2.2,
# via3.1a/via3.2, via4.1a/via4.2 in libs.tech/klayout/drc/sky130A.lydrc). There is one via
# family per level, so as in gf180mcuD there is no vp_* counterpart and no gen_via3.py.
V = {("li1","m1"):(67,44,0.17,0.19),("m1","m2"):(68,44,0.15,0.17),
     ("m2","m3"):(69,44,0.20,0.20),("m3","m4"):(70,44,0.20,0.20),
     ("m4","m5"):(71,44,0.80,0.80)}
W = 16.0   # arm width, wide enough that every cut lands inside - via4 needs 12 um for n=8

def build(lo, up, ncuts):
    name = "vc_%s_%s_n%d" % (lo, up, ncuts)
    ly = pya.Layout(); ly.dbu = 0.001
    top = ly.create_cell(name)
    lo_n, lo_d, lo_pn, lo_pd = M[lo]
    up_n, up_d, up_pn, up_pd = M[up]
    vn, vd, vs, vsp = V[(lo, up)]
    top.shapes(ly.layer(lo_n, lo_d)).insert(pya.DBox(0.0, 0.0, W, 51.0))
    top.shapes(ly.layer(up_n, up_d)).insert(pya.DBox(0.0, 49.0, W, 100.0))
    pitch = vs + vsp
    span = ncuts * pitch - vsp
    if span > W - 1.0:
        # The row of cuts would run off the landing metal. Widening the arm per cut count would
        # change its resistance with n and break the contact-resistance table, which subtracts
        # the n=1 metal to isolate the vias, so this combination is skipped instead.
        print("skipped %s: %d cuts span %.2f um, landing metal is %.1f um" % (name, ncuts, span, W))
        return
    x0 = W/2.0 - span / 2.0
    for i in range(ncuts):
        x = x0 + i * pitch
        top.shapes(ly.layer(vn, vd)).insert(pya.DBox(x, 50.0 - vs/2, x + vs, 50.0 + vs/2))
    for (mn, md, nm, y) in [(lo_pn, lo_pd, "l", 0.5), (up_pn, up_pd, "u", 99.5)]:
        top.shapes(ly.layer(mn, md)).insert(pya.DBox(W/2-0.1, y-0.1, W/2+0.1, y+0.1))
        top.shapes(ly.layer(mn, md)).insert(pya.DText(nm, W/2, y))
    ly.write(os.path.join(OUT, name + ".gds"), GDS_OPTS); print("wrote " + name)

for (lo, up) in V:
    for n in (1, 2, 3, 4, 8):
        build(lo, up, n)
