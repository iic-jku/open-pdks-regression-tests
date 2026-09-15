import os, pya
OUT = os.path.join(os.path.dirname(os.path.realpath(__file__)), "..", "layout")

# KLayout stamps the wall clock into the GDS header unless this is off, which would make every
# regenerated layout differ from the committed one. "make layouts-check" asserts they match.
GDS_OPTS = pya.SaveLayoutOptions()
GDS_OPTS.gds2_write_timestamps = False
M = {"m1":(34,0,34,10),"m2":(36,0,36,10),"m3":(42,0,42,10),"m4":(46,0,46,10),
     "m5":(81,0,81,10)}
# via layer, cut size, min cut spacing. Every via in this PDK is a fixed 0.26 x 0.26 um cut on
# 0.26 um minimum spacing (rules V<n>.1 and V<n>.2a in
# libs.tech/klayout/tech/drc/rule_decks/via.rb), and all four carry 4500 mOhm per cut, so
# unlike the IHP PDKs there is no second via family and hence no vp_* chain: gen_via3.py has
# no counterpart here and is not part of this bench. Via5 appears in the shared gf180mcu layer
# map but has no metal above it in this metal option.
V = {("m1","m2"):(35,0,0.26,0.26),("m2","m3"):(38,0,0.26,0.26),
     ("m3","m4"):(40,0,0.26,0.26),("m4","m5"):(41,0,0.26,0.26)}
W = 12.0   # arm width, wide enough that every cut lands inside

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
