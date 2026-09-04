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
src.read("/foss/pdks/ihp-sg13g2/libs.ref/sg13g2_stdcell/gds/sg13g2_stdcell.gds")
cell = src.cell("sg13g2_inv_1")

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
inv = out.create_cell("sg13g2_inv_1")
inv.copy_tree(cell)
top.insert(pya.DCellInstArray(inv.cell_index(), pya.DTrans()))

c = pin_box.center()
# via, M2 pad on the pin box, then a 0.5 x 200 um Metal2 wire running +x
top.shapes(out.layer(19, 0)).insert(pya.DBox(c.x - 0.095, c.y - 0.095, c.x + 0.095, c.y + 0.095))
top.shapes(out.layer(10, 0)).insert(pin_box)
top.shapes(out.layer(10, 0)).insert(pya.DBox(c.x, c.y - 0.25, c.x + 200.0, c.y + 0.25))
out.write(os.path.join(os.path.dirname(os.path.realpath(__file__)), "..", "layout", "hier_test.gds"), GDS_OPTS)
print("wrote layout/hier_test.gds")
