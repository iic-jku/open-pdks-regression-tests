# A real transistor with a long, unambiguous wire on its gate, to test whether
# "ext2spice hierarchy on" drops the wire's substrate capacitance.
# The wire is on Metal2 (unused inside the standard cell), reached by one Via1 in the A pin.
import os
import pya

# KLayout stamps the wall clock into the GDS header unless this is off, which would make every
# regenerated layout differ from the committed one. "make layouts-check" asserts they match.
GDS_OPTS = pya.SaveLayoutOptions()
GDS_OPTS.gds2_write_timestamps = False

src = pya.Layout()
LIB = os.environ.get("STD_CELL_LIBRARY", "sg13cmos5l_stdcell")
PDK = os.environ.get("PDKPATH", "/foss/pdks/ihp-sg13cmos5l")
CELL = LIB.replace("_stdcell", "") + "_inv_1"
src.read("%s/libs.ref/%s/gds/%s.gds" % (PDK, LIB, LIB))
cell = src.cell(CELL)

pin_pt = pin_box = None
for dt in (2, 25, 0):
    li = src.find_layer(8, dt)
    if li is None:
        continue
    for sh in cell.shapes(li).each():
        if sh.is_text() and sh.text.string == "A":
            pin_pt = sh.dtext.position()
    if pin_pt:
        break
assert pin_pt, "no A label on Metal1"
li = src.find_layer(8, 2)
if li is not None:
    for sh in cell.shapes(li).each():
        if sh.is_box() and sh.dbox.contains(pin_pt):
            pin_box = sh.dbox
if pin_box is None:
    pin_box = pya.DBox(pin_pt.x - 0.1, pin_pt.y - 0.1, pin_pt.x + 0.1, pin_pt.y + 0.1)
print("A pin at", pin_pt, "box", pin_box)

out = pya.Layout()
out.dbu = src.dbu
top = out.create_cell("hier_test")
inv = out.create_cell(CELL)
inv.copy_tree(cell)
top.insert(pya.DCellInstArray(inv.cell_index(), pya.DTrans()))

c = pin_box.center()
# via, M2 pad on the pin box, then a 0.5 x 200 um Metal2 wire running +x
top.shapes(out.layer(19, 0)).insert(pya.DBox(c.x - 0.095, c.y - 0.095, c.x + 0.095, c.y + 0.095))
top.shapes(out.layer(10, 0)).insert(pin_box)
top.shapes(out.layer(10, 0)).insert(pya.DBox(c.x, c.y - 0.25, c.x + 200.0, c.y + 0.25))
LAY = os.path.join(os.path.dirname(os.path.realpath(__file__)), "..", "layout")
out.write(os.path.join(LAY, "hier_test.gds"), GDS_OPTS)
print("wrote layout/hier_test.gds")

# The bare standard cell as well, as the device-bearing reference next to hier_test. In the
# sg13g2 bench this layout is committed without a generator, so "make layouts" never
# reproduces it and "make layouts-check" cannot notice: it diffs a copy of layout/ against the
# regenerated one, and a file nothing rewrites matches itself. Writing it here closes that.
bare = pya.Layout()
bare.dbu = src.dbu
bare_top = bare.create_cell(CELL)
bare_top.copy_tree(cell)
bare.write(os.path.join(LAY, CELL + ".gds"), GDS_OPTS)
print("wrote layout/%s.gds" % CELL)
